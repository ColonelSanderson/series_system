module ControlledByAgent

  def self.included(base)
    base.extend(ClassMethods)
    base.include(Relationships)

    base.define_relationship(:name => :controlled_by,
                             :json_property => 'controlled_by',
                             :contains_references_to_types => proc {[AgentCorporateEntity]})
  end


  module ClassMethods

    def sequel_to_jsonmodel(objs, opts = {})
      jsons = super

      jsons.each do |json|
        self.sort_and_set_current_controlling_agency(json)
      end

      jsons
    end


    def sort_and_set_current_controlling_agency(json)
      today = Date.today

      ASUtils.wrap(json['controlled_by']).each do |agency|
        agency['current'] = false
        if agency['start_date'] and Date.parse(agency['start_date']) <= today
          if !agency['end_date'] or Date.parse(agency['end_date']) > today
            agency['current'] = true
          end
        end
      end
    end

  end

end