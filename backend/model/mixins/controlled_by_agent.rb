module ControlledByAgent

  def self.included(base)
    base.include(Relationships)

    base.define_relationship(:name => :controlled_by,
                             :json_property => 'controlled_by',
                             :contains_references_to_types => proc {[AgentCorporateEntity]})
  end

  def self.sequel_to_jsonmodel(objs, opts = {})
    jsons = super

    jsons.each do |json|
      self.sort_and_set_current_controlling_agency(json)
    end

    jsons
  end

  def self.sort_and_set_current_controlling_agency(json)
    today = Date.today
    json['controlled_by'] = ASUtils.wrao(json['controlled_by']).map do |agency|
      if agency['start_date'] and Date.parse(agency['start_date']) <= today
        if !agency['end_date'] or Date.parse(agency['end_date']) > today
          agency['current'] = true
        end
      end
    end

    json['controlled_by'].sort! do |agency|
      agency['start_date']
    end
  end

end