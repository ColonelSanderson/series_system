module ControlledRecord

  def self.included(base)
    base.extend(ClassMethods)
  end


  def update_from_json(json, opts = {}, apply_nested_records = true)
    self.class.ensure_controller_is_not_dead(json)
    super
  end


  def responsible_agency
    ds = self.class.controlling_agencies_dataset

    if self.respond_to? :root_record_id
      ds = ds.filter("#{self.class.table_name}_id_0".intern => self.id)
      if ds.empty?
        if self.parent_id
          self.class[self.parent_id].responsible_agency
        else
          self.class.root_model[self.root_record_id].responsible_agency
        end
      else
        AgentCorporateEntity[ds.first[:agency_id]]
      end
    else
      AgentCorporateEntity[ds.filter("#{self.class.table_name}_id_0".intern => self.id).first[:agency_id]]
    end
  end


  def other_responsible_agencies
    # for now we're only supporting this at series level
    return [] if self.respond_to? :root_record_id

    # this is only pertinent to models that have trees under them
    return [] unless self.class.respond_to? :node_model

    children_ids = self.class.node_model.filter(:root_record_id => self.id).select(:id)

    self.class.controlling_agencies_dataset
      .filter("#{self.class.node_model.table_name}_id_0".intern => children_ids)
      .map{|row| row[:agency_id]}
      .uniq
      .map{|id| AgentCorporateEntity[id]}
  end


  module ClassMethods
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


    def controlling_agencies_dataset
      @controlling_agencies_dataset ||=
        db[:series_system_rlshp]
        .filter(:jsonmodel_type => 'series_system_agent_record_ownership_relationship')
        .filter(:relationship_target_record_type => 'agent_corporate_entity')
        .filter(:end_date => nil)
        .select(Sequel.as(:relationship_target_id, :agency_id))
    end
  end

end
