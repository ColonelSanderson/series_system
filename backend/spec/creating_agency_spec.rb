require 'spec_helper'

describe 'Series System' do

  describe 'Creating Agencies' do

    let!(:agency) {
      create(:json_agent_corporate_entity,
             :dates_of_existence => [{
                                       :label => 'existence',
                                       :date_type => 'range',
                                       :begin => '2019-01-01'
                                     }])
    }

    let!(:agency2) {
      create(:json_agent_corporate_entity,
             :dates_of_existence => [{
                                       :label => 'existence',
                                       :date_type => 'range',
                                       :begin => '2010-01-01'
                                     }])
    }

    # Required by the validation rules
    let!(:current_controller) {
      {
        :jsonmodel_type => 'series_system_agent_record_ownership_relationship',
        :relator => 'is_controlled_by',
        :start_date => '2019-02-01',
        :ref => agency.uri
      }
    }

    let!(:creation_relationship) {
      {
        :jsonmodel_type => 'series_system_agent_record_creation_relationship',
        :relator => 'established_by',
        :start_date => '2019-02-01',
        :ref => agency.uri
      }
    }

    let!(:creation_relationship2) {
      {
        :jsonmodel_type => 'series_system_agent_record_creation_relationship',
        :relator => 'established_by',
        :start_date => '2019-02-01',
        :ref => agency2.uri
      }
    }


    it 'reports on relationships with directly attached creation relationships' do
      series = create(:json_resource, :series_system_agent_relationships => [current_controller, creation_relationship])

      ao = create(:json_archival_object,
                  :resource => { :ref => series.uri},
                  :series_system_agent_relationships => [current_controller, creation_relationship2])


      expect(Resource.to_jsonmodel(series.id)['creating_agency']['ref']).to eq(agency.uri)
      expect(ArchivalObject.to_jsonmodel(ao.id)['creating_agency']['ref']).to eq(agency2.uri)
    end

    it 'propagates relationships down the tree' do
      series = create(:json_resource, :series_system_agent_relationships => [current_controller, creation_relationship])

      ao = create(:json_archival_object,
                  :resource => { :ref => series.uri})


      expect(ArchivalObject.to_jsonmodel(ao.id)['creating_agency']['ref']).to eq(agency.uri)
    end

    it 'is absent if there are no creation relationships' do
      series = create(:json_resource, :series_system_agent_relationships => [current_controller])
      ao = create(:json_archival_object,
                  :resource => { :ref => series.uri})

      expect(ArchivalObject.to_jsonmodel(ao.id)['creating_agency']).to be_nil
    end

  end
end
