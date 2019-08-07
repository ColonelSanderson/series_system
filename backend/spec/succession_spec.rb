require 'spec_helper'

describe 'Series System' do

  describe 'Succession Dates' do

    let!(:agency_a) {
      create(:json_agent_corporate_entity,
             :dates_of_existence => [{
                                       :label => 'existence',
                                       :date_type => 'range',
                                       :begin => '2019-01-01'
                                     }])
    }

    let!(:agency_b) {
      create(:json_agent_corporate_entity,
             :dates_of_existence => [{
                                       :label => 'existence',
                                       :date_type => 'range',
                                       :begin => '2010-01-01'
                                     }])
    }

    it "for supercedes cannot be before the start date of source agent" do
      agency_a_json = AgentCorporateEntity.to_jsonmodel(agency_a.id)

      succession_rlshp = {
        'jsonmodel_type' => 'series_system_agent_agent_succession_relationship',
        'relator' => 'supercedes',
        'start_date' => '2018-12-31',
        'ref' => agency_b.uri
      }

      agency_a_json['series_system_agent_relationships'] = [succession_rlshp]

      RequestContext.in_global_repo do
        expect {AgentCorporateEntity[agency_a.id].update_from_json(agency_a_json)}.to raise_error(Sequel::ValidationFailed)
      end
    end

    it "for precedes cannot be before the start date of target agent" do
      agency_a_json = AgentCorporateEntity.to_jsonmodel(agency_a.id)

      succession_rlshp = {
        'jsonmodel_type' => 'series_system_agent_agent_succession_relationship',
        'relator' => 'precedes',
        'start_date' => '2009-12-31',
        'ref' => agency_b.uri
      }

      agency_a_json['series_system_agent_relationships'] = [succession_rlshp]

      RequestContext.in_global_repo do
        expect {AgentCorporateEntity[agency_a.id].update_from_json(agency_a_json)}.to raise_error(Sequel::ValidationFailed)
      end
    end

    it "for supercedes ok if after start date of source agent" do
      agency_a_json = AgentCorporateEntity.to_jsonmodel(agency_a.id)

      succession_rlshp = {
        'jsonmodel_type' => 'series_system_agent_agent_succession_relationship',
        'relator' => 'supercedes',
        'start_date' => '2019-01-02',
        'ref' => agency_b.uri
      }

      agency_a_json['series_system_agent_relationships'] = [succession_rlshp]

      RequestContext.in_global_repo do
        expect {AgentCorporateEntity[agency_a.id].update_from_json(agency_a_json)}.to_not raise_error
      end
    end

    it "for precedes ok if after start date of target agent" do
      agency_a_json = AgentCorporateEntity.to_jsonmodel(agency_a.id)

      succession_rlshp = {
        'jsonmodel_type' => 'series_system_agent_agent_succession_relationship',
        'relator' => 'precedes',
        'start_date' => '2019-01-02',
        'ref' => agency_b.uri
      }

      agency_a_json['series_system_agent_relationships'] = [succession_rlshp]

      RequestContext.in_global_repo do
        expect {AgentCorporateEntity[agency_a.id].update_from_json(agency_a_json)}.to_not raise_error
      end
    end

    it "for supercedes ok if after start date of source agent" do
      agency_a_json = AgentCorporateEntity.to_jsonmodel(agency_a.id)

      succession_rlshp = {
        'jsonmodel_type' => 'series_system_agent_agent_succession_relationship',
        'relator' => 'supercedes',
        'start_date' => '2019-01-01',
        'ref' => agency_b.uri
      }

      agency_a_json['series_system_agent_relationships'] = [succession_rlshp]

      RequestContext.in_global_repo do
        expect {AgentCorporateEntity[agency_a.id].update_from_json(agency_a_json)}.to_not raise_error
      end
    end

    it "for precedes ok if after start date of target agent" do
      agency_a_json = AgentCorporateEntity.to_jsonmodel(agency_a.id)

      succession_rlshp = {
        'jsonmodel_type' => 'series_system_agent_agent_succession_relationship',
        'relator' => 'precedes',
        'start_date' => '2015-01-01',
        'ref' => agency_b.uri
      }

      agency_a_json['series_system_agent_relationships'] = [succession_rlshp]

      RequestContext.in_global_repo do
        expect {AgentCorporateEntity[agency_a.id].update_from_json(agency_a_json)}.to_not raise_error
      end
    end

    it "for supercedes cannot be before the start date of source agent upon creation too" do
      extra_json = {
        'dates_of_existence' => [{
                                  'label' => 'existence',
                                  'date_type' => 'range',
                                  'begin' => '2019-01-01'
                                }],
        'series_system_agent_relationships' => [
          {
            'jsonmodel_type' => 'series_system_agent_agent_succession_relationship',
            'relator' => 'supercedes',
            'start_date' => '2018-12-31',
            'ref' => agency_b.uri
          }
        ]
      }

      RequestContext.in_global_repo do
        expect {
          AgentCorporateEntity.create_from_json(
            build(:json_agent_corporate_entity,
                  extra_json))
        }.to raise_error(Sequel::ValidationFailed)
      end
    end
  end

end