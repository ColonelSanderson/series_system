require 'date'

module ControlledRecord

  GRACE_DAYS = 90
  ControlRelationship = Struct.new(:definition, :jsonmodel, :agency_model, :record, :agency)


  def self.included(base)
    base.extend(ClassMethods)
  end


  def update_from_json(json, opts = {}, apply_nested_records = true)
    self.class.ensure_controller_is_not_dead(json)
    super
  end


  def responsible_agency
    agency_uri = self.class.controlling_agency_uris([self.id]).fetch(self.id, false)

    return agency_uri if agency_uri

    unless self.respond_to? :parent_id
      # something terrible has happened, but let's pretend everytihng is fine
      return ''
    end

    if self.parent_id
      self.class[self.parent_id].responsible_agency
    else
      self.class.root_model[self.root_record_id].responsible_agency
    end
  end


  def other_responsible_agencies
    # for now we're only supporting this at series level
    return {} if self.respond_to? :root_record_id

    # this is only pertinent to models that have trees under them
    return {} unless self.class.respond_to? :node_model

    # For very large resource trees, hitting the relationship code was too slow
    # here.  Fast pathing this by hitting the DB directly.
    my_agency = self.responsible_agency

    DB.open do |db|
      db[:series_system_rlshp]
      .join(:archival_object, Sequel.qualify(:archival_object, :id) => Sequel.qualify(:series_system_rlshp, :archival_object_id_0))
      .filter(Sequel.qualify(:archival_object, :root_record_id) => self.id)
      .filter(Sequel.qualify(:series_system_rlshp, :jsonmodel_type) => self.class.control_relationship.jsonmodel)
      .filter(Sequel.qualify(:series_system_rlshp, :end_date) => nil)
      .select(
        Sequel.as(Sequel.qualify(:archival_object, :id), :archival_object_id),
        Sequel.as(Sequel.qualify(:series_system_rlshp, :agent_corporate_entity_id_0),
                       :agency_id))
      .map {|row|
        agency_uri = JSONModel(:agent_corporate_entity).uri_for(row[:agency_id])

        if agency_uri != my_agency
          [row[:archival_object_id], agency_uri]
        end
      }.compact.to_h
    end
  end


  # The agencies that have controlled a given record over various time periods.
  RecordControllingAgencies = Struct.new(:id, :agency_controls)

  # The range of dates a given agency controlled some record.
  AgencyControlPeriod = Struct.new(:agency, :range)

  def calculate_grace(branch, inherited_controls = [])
    while !branch.empty?
      current_node = branch.shift
      new_inherited = []

      if current_node.agency_controls.empty?
        # If this node doesn't add any agency controls, we fully inherit from
        # the record above.
        new_inherited = inherited_controls
      else
        # Remove ranges based on new controls in this record.
        current_node.agency_controls.each do |control|
          inherited_controls.each do |inherited|
            split_range = inherited.range.remove_range(control.range)
            new_inherited.concat(split_range.map {|r| AgencyControlPeriod.new(inherited.agency, r)})
          end
        end
      end

      # Add new controls established by this record
      new_inherited += current_node.agency_controls

      inherited_controls = new_inherited
    end

    inherited_controls
  end

  def recent_responsible_agencies(age_days = GRACE_DAYS)
    # Our branch is the path to this record from the root of the tree, so it'll look like:
    #
    #  [[ArchivalObject, myid], [ArchivalObject, myparentid], ..., [Resource, root_record_id]]
    branch = []
    current_model = self.class
    current_id = self.id

    loop do
      branch << [current_model, current_id]

      if current_model.ancestors.include?(TreeNodes)
        next_row = current_model.filter(:id => current_id).select(:parent_id, :root_record_id).first

        if next_row[:parent_id]
          current_id = next_row[:parent_id]
        else
          # Next stop: root record
          current_model = self.class.root_model
          current_id = next_row[:root_record_id]
        end
      else
        # We've hit the root and we're done
        break
      end
    end

    # Group our branch by record type to fetch relationships in as few queries
    # as possible
    record_control_periods = {}

    controlling_rlshp = self.class.control_relationship.definition
    branch.group_by(&:first).each do |record_model, branch_entries|
      record_ids = branch_entries.map {|e| e[1]}

      controlling_relationships = controlling_rlshp.find_by_participant_ids(record_model, record_ids)
      controlling_relationships.each do |relationship|
        controlling_rlshp.reference_columns_for(record_model).each do |col|
          next unless relationship[:jsonmodel_type] == 'series_system_agent_record_ownership_relationship'

          if relationship[col]
            key = [record_model, relationship[col]]

            parsed_start = DateParse.date_parse_down(relationship.start_date)
            parsed_end = relationship.end_date ? DateParse.date_parse_up(relationship.end_date) : nil

            record_control_periods[key] ||= []
            record_control_periods[key] << AgencyControlPeriod.new(JSONModel(:agent_corporate_entity).uri_for(relationship[:agent_corporate_entity_id_0]),
                                                                   DateRange.new(parsed_start, parsed_end))
          end
        end
      end
    end

    controlling_agencies = branch.map {|key| RecordControllingAgencies.new(key[1], record_control_periods.fetch(key, []))}
    agency_end_dates = {}

    calculate_grace(controlling_agencies.reverse).each do |control|
      next if !control.range.end_date || (control.range.end_date + age_days) < Date.today()

      # If we don't have an entry yet, or if we've found a later end date, take
      # this one.
      if !agency_end_dates[control.agency] || agency_end_dates[control.agency] < control.range.end_date
        agency_end_dates[control.agency] = control.range.end_date
      end
    end

    agency_end_dates.map {|agency, end_date|
        {
          'ref' => agency,
          'end_date' => end_date.strftime('%Y-%m-%d')
        }
    }
  end


  module ClassMethods
    def sequel_to_jsonmodel(objs, opts = {})
      jsons = super
      jsons.zip(objs).each do |json, obj|
        json['responsible_agency'] = { 'ref' => obj.responsible_agency }
        json['recent_responsible_agencies'] = obj.recent_responsible_agencies

        if obj.class.my_jsonmodel.schema['properties'].has_key?('other_responsible_agencies')
          json['other_responsible_agencies'] = obj.other_responsible_agencies.values.uniq.map{|agency| { 'ref' => agency }}
        end
      end

      jsons
    end

    def create_from_json(json, opts = {})
      if AppConfig[:plugins].include?('qsa_migration_adapter')
        # You're the boss. Monkey away!
      else
        ensure_controller_is_not_dead(json)
      end

      super
    end


    def ensure_controller_is_not_dead(json)
      # fail if trying to assert that this record is controlled by a terminated agency

      # check each open control relationship
      json['series_system_agent_relationships'].select{|r| r['relator'] == 'is_controlled_by' && !r['end_date']}.each do |cr|
        target_table =  RelationshipRules.instance.model_for_jsonmodel_type(cr['relationship_target_record_type']).table_name

        # controlling agency is dead if it doesn't have any open (ie lacking an end date) 'existence' date sub-records
        controller_is_dead = db[target_table]
          .filter("#{target_table}__id".intern => cr['relationship_target_id'])
          .left_join(:date, "date__#{target_table}_id".intern => "#{target_table}__id".intern)
          .left_join(Sequel.as(:enumeration_value, :date_label), :id => :date__label_id)
          .filter(:date_label__value => 'existence')
          .filter(:date__end => nil)
          .count == 0

        if controller_is_dead
          errors = Sequel::Model::Errors.new
          errors.add('series_system_agent_relationships', 'Cannot be controlled by a terminated agency')
          raise Sequel::ValidationFailed.new(errors)
        end
      end
    end


    def controlling_agency_uris(ids)
      # given an array of record ids, returns a hash keyed on those ids
      # with values of the uris of the corresponding controlling agencies
      out = {}

      control_relationship.definition.find_by_participant_ids(self, ids).each do |r|
        next unless r.jsonmodel_type == control_relationship.jsonmodel
        next unless r.end_date.nil?
        out[r[control_relationship.record]] = control_relationship.agency_model.my_jsonmodel.uri_for(r[control_relationship.agency])
      end

      out
    end


    def control_relationship
      @control_reln_defn ||= find_control_relationship_defn
    end


    def find_control_relationship_defn
      rlshp_def = find_relationship('series_system_agent_relationships')
      jsonmodel_type = my_jsonmodel.record_type

      rule = RelationshipRules.instance.rules_for_jsonmodel_type(jsonmodel_type).find do |rule|
        rule.target_jsonmodel_category == :agent
      end

      relationship_type = rule.relationship_types.find do |relationship_type|
        relationship_type == 'ownership'
      end

      rlshp_jsonmodel_type = RelationshipRules.instance.build_relationship_jsonmodel_name(rule, relationship_type)

      controlling_agent_model = AgentCorporateEntity
      controlling_agent_reference_col = rlshp_def.reference_columns_for(controlling_agent_model).first
      record_reference_col = rlshp_def.reference_columns_for(self).first

      ControlRelationship.new(rlshp_def,
                              rlshp_jsonmodel_type,
                              controlling_agent_model,
                              record_reference_col,
                              controlling_agent_reference_col)
    end

  end

end
