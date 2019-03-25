module ControlOfRecords

  def self.included(base)
    base.extend(ClassMethods)
  end


  def update_from_json(json, opts = {}, apply_nested_records = true)
    self.class.ensure_controller_is_not_dead(json)

    if self.is_a?(AgentCorporateEntity) && json['dates_of_existence'].all?{|d| d['end']}
      # trying to terminate the agency
      # so fail if it has any open control relationships

      open_control = db[:series_system_rlshp]
        .filter(:jsonmodel_type => 'series_system_agent_record_ownership_relationship')
        .filter(:relationship_target_record_type => 'agent_corporate_entity')
        .filter(:relationship_target_id => self.id)
        .filter(:end_date => nil)
        .count

      if open_control > 0
        raise ConflictException.new("Unable to terminate agency. It currently has control of #{open_control} record#{open_control > 1 ? 's' : ''}.")
      end
    end

    super
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

        # controlling agency is dead if it doesn't have any open (ie lacking an end date) 'existence' date sub-records
        controller_is_dead = db[cr['relationship_target_record_type'].intern]
          .filter("#{cr['relationship_target_record_type']}__id".intern => cr['relationship_target_id'])
          .left_join(:date, "date__#{cr['relationship_target_record_type']}_id".intern => "#{cr['relationship_target_record_type']}__id".intern)
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
  end

end
