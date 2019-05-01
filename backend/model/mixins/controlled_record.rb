module ControlledRecord

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


  def recent_responsible_agencies(opts = {})
    age_days = opts.fetch(:age_days, 90)
    self.class.controlling_agency_uris([self.id], :age_days => age_days)
  end


  module ClassMethods
    def sequel_to_jsonmodel(objs, opts = {})
      jsons = super
      jsons.zip(objs).each do |json, obj|
        json['responsible_agency'] = { 'ref' => obj.responsible_agency }

        if obj.class.my_jsonmodel.schema['properties'].has_key?('other_responsible_agencies')
          json['other_responsible_agencies'] = obj.other_responsible_agencies.map{|id, agency| { 'ref' => agency }}
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


    def controlling_agency_uris(ids, opts = {})
      # given an array of record ids, returns a hash keyed on those ids
      # with values of the uris of the corresponding controlling agencies
      # if an :age_days opt is passed then return non-current controlling agencies
      # that had control within that many days, and return the end_date along with the uri

      out = {}

      control_relationship.definition.find_by_participant_ids(self, ids).each do |r|
        next unless r.jsonmodel_type == control_relationship.jsonmodel

        if opts[:age_days]
          next if r.end_date.nil?
          next if Time.new(*r.end_date.split('-')) < Time.now() - (60*60*24 * opts[:age_days].to_i)
          out[r[control_relationship.record]] = {
            :ref => control_relationship.agency_model.my_jsonmodel.uri_for(r[control_relationship.agency]),
            :end_date => r.end_date
          }
        else
          next unless r.end_date.nil?
          out[r[control_relationship.record]] = control_relationship.agency_model.my_jsonmodel.uri_for(r[control_relationship.agency])
        end
      end

      out
    end


    private


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
