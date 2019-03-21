require 'spec_helper'
require 'pp'

describe 'Series System' do

  describe 'Control of Records' do

    it 'ensures an item has exactly one current controlling agency' do
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
      # hmm only have a ref to the agency when validating
    end


    it 'does not allow dates of control to overlap for an item' do
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

  end
end
