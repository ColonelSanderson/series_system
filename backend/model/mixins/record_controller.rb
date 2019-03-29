module RecordController

  def update_from_json(json, opts = {}, apply_nested_records = true)
    if json['dates_of_existence'].all?{|d| d['end']}
      # trying to terminate the agency
      # so fail if it has any open control relationships

      open_control = db[:series_system_rlshp]
        .filter(:jsonmodel_type => 'series_system_agent_record_ownership_relationship')
        .filter(:relationship_target_record_type => 'agent_corporate_entity')
        .filter(:relationship_target_id => self.id)
        .filter(:end_date => nil)
        .count

      if open_control > 0
        errors = Sequel::Model::Errors.new
        errors.add('dates_of_existence', "Unable to terminate agency that controls records")
        raise Sequel::ValidationFailed.new(errors)
      end
    end

    super
  end

end
