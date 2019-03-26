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
        raise ConflictException.new("Unable to terminate agency. It currently has control of #{open_control} record#{open_control > 1 ? 's' : ''}.")
      end
    end

    super
  end

end
