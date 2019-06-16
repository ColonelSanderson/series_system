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

    children_ids = self.class.node_model.filter(:root_record_id => self.id).select(:id).all.map{|r| r[:id]}

    self.class.node_model.controlling_agency_uris(children_ids)
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
    # The record we're working on as we walk our way up the tree
    current_record = self

    # "branch" refers to the chain of records from the root of the tree down to
    # the record of the interest.  For each record in the branch, we record a
    # RecordControllingAgencies entry that tells us which agencies had control
    # on which dates.
    branch_controllers = []

    while current_record
      controlling_relationships = self.class.control_relationship.definition.find_by_participant(current_record)

      current_record_controllers = RecordControllingAgencies.new(self.id, [])

      controlling_relationships.each do |r|
        parsed_start = DateParse.date_parse_down(r.start_date)
        parsed_end = r.end_date ? DateParse.date_parse_up(r.end_date) : nil

        if parsed_start
          control_period = AgencyControlPeriod.new(r.other_referent_than(current_record).uri,
                                                   DateRange.new(parsed_start, parsed_end))
          current_record_controllers.agency_controls << control_period
        end
      end

      branch_controllers.unshift(current_record_controllers)

      # Move up the tree
      if current_record.is_a?(TreeNodes)
        if current_record.parent_id
          current_record = current_record.class[current_record.parent_id]
        else
          current_record = current_record.class.root_model[current_record.root_record_id]
        end
      else
        # If we were at the root, there's no further to go.
        break
      end
    end

    agency_end_dates = {}

    calculate_grace(branch_controllers).each do |control|
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
      ensure_controller_is_not_dead(json)
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
