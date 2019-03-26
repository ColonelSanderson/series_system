require 'spec_helper'

describe 'Series System' do

  describe 'Control of Records' do

    it 'ensures a record has exactly one current controlling agency' do
      current_agency = create(:json_agent_corporate_entity,
                              :dates_of_existence => [{
                                                        :label => 'existence',
                                                        :date_type => 'range',
                                                        :begin => '2019-01-01'
                                                      }])

      old_agency = create(:json_agent_corporate_entity,
                          :dates_of_existence => [{
                                                    :label => 'existence',
                                                    :date_type => 'range',
                                                    :begin => '1999-01-01',
                                                    :end => '2001-01-01'
                                                  }])

      current_controller = {
        :jsonmodel_type => 'series_system_agent_record_ownership_relationship',
        :relator => 'is_controlled_by',
        :start_date => '2019-02-01',
        :ref => current_agency.uri
      }

      old_controller = {
        :jsonmodel_type => 'series_system_agent_record_ownership_relationship',
        :relator => 'is_controlled_by',
        :start_date => '1999-02-01',
        :end_date => '2001-01-01',
        :ref => old_agency.uri
      }

      expect { create(:json_resource,
                      :series_system_agent_relationships => []) }.to raise_error(JSONModel::ValidationException)

      expect { create(:json_resource,
                      :series_system_agent_relationships => [old_controller]) }.to raise_error(JSONModel::ValidationException)

      expect { create(:json_resource,
                      :series_system_agent_relationships => [current_controller]) }.to_not raise_error

      expect { create(:json_resource,
                      :series_system_agent_relationships => [current_controller, old_controller]) }.to_not raise_error
    end


    it 'does not allow terminated agencies to control records' do
      terminated_agency = create(:json_agent_corporate_entity,
                                 :dates_of_existence => [{
                                                           :label => 'existence',
                                                           :date_type => 'range',
                                                           :begin => '1999-01-01',
                                                           :end => '2001-01-01'
                                                         }])

      controlled_by_terminated_agency = {
        :jsonmodel_type => 'series_system_agent_record_ownership_relationship',
        :relator => 'is_controlled_by',
        :start_date => '2019-02-01',
        :ref => terminated_agency.uri
      }

      expect {
        create(:json_resource, :series_system_agent_relationships => [controlled_by_terminated_agency])
      }.to raise_error(JSONModel::ValidationException)
    end


    it 'does not allow agencies with current control of records to be terminated' do
      current_agency = create(:json_agent_corporate_entity,
                              :dates_of_existence => [{
                                                        :label => 'existence',
                                                        :date_type => 'range',
                                                        :begin => '2019-01-01'
                                                      }])
      current_controller = {
        :jsonmodel_type => 'series_system_agent_record_ownership_relationship',
        :relator => 'is_controlled_by',
        :start_date => '2019-01-01',
        :ref => current_agency.uri
      }

      create(:json_resource, :series_system_agent_relationships => [current_controller])

      # refresh the agency because its lock_version gets bumped when the relationship is created
      current_agency = AgentCorporateEntity.to_jsonmodel(current_agency.id)

      current_agency['dates_of_existence'][0]['end'] = '2019-01-31'

      RequestContext.in_global_repo do
        expect { AgentCorporateEntity[current_agency.id].update_from_json(current_agency) }.to raise_error(ConflictException)
      end
    end


    it 'does not allow dates of control to overlap for a record' do
      current_agency = create(:json_agent_corporate_entity,
                              :dates_of_existence => [{
                                                        :label => 'existence',
                                                        :date_type => 'range',
                                                        :begin => '2019-01-01'
                                                      }])

      old_agency = create(:json_agent_corporate_entity,
                          :dates_of_existence => [{
                                                    :label => 'existence',
                                                    :date_type => 'range',
                                                    :begin => '2019-01-01',
                                                    :end => '2019-03-01'
                                                  }])

      current_controller = {
        :jsonmodel_type => 'series_system_agent_record_ownership_relationship',
        :relator => 'is_controlled_by',
        :start_date => '2019-02-01',
        :ref => current_agency.uri
      }

      overlapping_controller = {
        :jsonmodel_type => 'series_system_agent_record_ownership_relationship',
        :relator => 'is_controlled_by',
        :start_date => '2019-01-01',
        :end_date => '2019-02-02',
        :ref => old_agency.uri
      }

      nearly_overlapping_controller = {
        :jsonmodel_type => 'series_system_agent_record_ownership_relationship',
        :relator => 'is_controlled_by',
        :start_date => '2019-01-01',
        :end_date => '2019-02-01',
        :ref => old_agency.uri
      }

      less_specific_not_overlapping_controller = {
        :jsonmodel_type => 'series_system_agent_record_ownership_relationship',
        :relator => 'is_controlled_by',
        :start_date => '2010',
        :end_date => '2019',
        :ref => old_agency.uri
      }

      expect { create(:json_resource,
                      :series_system_agent_relationships => [current_controller, nearly_overlapping_controller]) }.to_not raise_error

      expect { create(:json_resource,
                      :series_system_agent_relationships => [current_controller,
                                                             overlapping_controller]) }.to raise_error(JSONModel::ValidationException)
      expect { create(:json_resource,
                      :series_system_agent_relationships => [current_controller, less_specific_not_overlapping_controller]) }.to_not raise_error

    end


    it 'ensures control relationships have a start date' do
      current_agency = create(:json_agent_corporate_entity,
                              :dates_of_existence => [{
                                                        :label => 'existence',
                                                        :date_type => 'range',
                                                        :begin => '2019-01-01'
                                                      }])

      no_start_controller = {
        :jsonmodel_type => 'series_system_agent_record_ownership_relationship',
        :relator => 'is_controlled_by',
        :ref => current_agency.uri
      }

      expect { create(:json_resource,
                      :series_system_agent_relationships => [no_start_controller]) }.to raise_error(JSONModel::ValidationException)
    end


    it 'allows items to be controlled by an agency other than the series controller' do
      series_control_agency = create(:json_agent_corporate_entity,
                                     :dates_of_existence => [{
                                                               :label => 'existence',
                                                               :date_type => 'range',
                                                               :begin => '2019-01-01'
                                                             }])

      item_control_agency = create(:json_agent_corporate_entity,
                                   :dates_of_existence => [{
                                                             :label => 'existence',
                                                             :date_type => 'range',
                                                             :begin => '2019-01-01'
                                                           }])

      series_controller = {
        :jsonmodel_type => 'series_system_agent_record_ownership_relationship',
        :relator => 'is_controlled_by',
        :start_date => '2019-01-01',
        :ref => series_control_agency.uri
      }

      item_controller = {
        :jsonmodel_type => 'series_system_agent_record_ownership_relationship',
        :relator => 'is_controlled_by',
        :start_date => '2019-01-01',
        :ref => item_control_agency.uri
      }

      series = create(:json_resource, :series_system_agent_relationships => [series_controller])

      expect { create(:json_archival_object,
                      :resource => { :ref => series.uri},
                      :series_system_agent_relationships => [item_controller]) }.to_not raise_error
    end

  end
end
