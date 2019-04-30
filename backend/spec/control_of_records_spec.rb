require 'spec_helper'

describe 'Series System' do

  describe 'Control of Records' do

    let!(:current_agency) {
      create(:json_agent_corporate_entity,
             :dates_of_existence => [{
                                       :label => 'existence',
                                       :date_type => 'range',
                                       :begin => '2019-01-01'
                                     }])
    }

    let!(:old_agency) {
      create(:json_agent_corporate_entity,
             :dates_of_existence => [{
                                       :label => 'existence',
                                       :date_type => 'range',
                                       :begin => '1999-01-01',
                                       :end => '2001-01-01'
                                     }])
    }

    let!(:current_controller) {
      {
        :jsonmodel_type => 'series_system_agent_record_ownership_relationship',
        :relator => 'is_controlled_by',
        :start_date => '2019-02-01',
        :ref => current_agency.uri
      }
    }

    let!(:old_controller) {
      {
        :jsonmodel_type => 'series_system_agent_record_ownership_relationship',
        :relator => 'is_controlled_by',
        :start_date => '1999-02-01',
        :end_date => '2001-01-01',
        :ref => old_agency.uri
      }
    }


    it 'ensures a series has exactly one current controlling agency' do
      expect { create(:json_resource,
                      :series_system_agent_relationships => []) }.to raise_error(JSONModel::ValidationException)

      expect { create(:json_resource,
                      :series_system_agent_relationships => [old_controller]) }.to raise_error(JSONModel::ValidationException)

      expect { create(:json_resource,
                      :series_system_agent_relationships => [current_controller]) }.to_not raise_error

      expect { create(:json_resource,
                      :series_system_agent_relationships => [current_controller, old_controller]) }.to_not raise_error
    end


    it 'ensures a series which has ceased to exist still has a current controlling agency' do
      expect { create(:json_resource,
                      :dates => [{
                                   :label => 'existence',
                                   :date_type => 'inclusive',
                                   :begin => '1999-01-01',
                                   :end => '2001-01-01'
                                 }],
                      :series_system_agent_relationships => [old_controller]) }.to raise_error(JSONModel::ValidationException)
    end


    it 'does not allow terminated agencies to control records' do
      terminated_agency =
        create(:json_agent_corporate_entity,
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
      immortal_agency =
        create(:json_agent_corporate_entity,
               :dates_of_existence => [{
                                         :label => 'existence',
                                         :date_type => 'range',
                                         :begin => '2019-01-01'
                                       }])

      open_controller = {
        :jsonmodel_type => 'series_system_agent_record_ownership_relationship',
        :relator => 'is_controlled_by',
        :start_date => '2019-01-01',
        :ref => immortal_agency.uri
      }

      create(:json_resource, :series_system_agent_relationships => [open_controller])

      # refresh the agency because its lock_version gets bumped when the relationship is created
      immortal_agency = AgentCorporateEntity.to_jsonmodel(immortal_agency.id)

      immortal_agency['dates_of_existence'][0]['end'] = '2019-01-31'

      RequestContext.in_global_repo do
        expect { AgentCorporateEntity[immortal_agency.id].update_from_json(immortal_agency) }.to raise_error(Sequel::ValidationFailed)
      end
    end


    it 'does not allow dates of control to overlap for a record' do
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
      no_start_controller = {
        :jsonmodel_type => 'series_system_agent_record_ownership_relationship',
        :relator => 'is_controlled_by',
        :ref => current_agency.uri
      }

      expect { create(:json_resource,
                      :series_system_agent_relationships => [no_start_controller]) }.to raise_error(JSONModel::ValidationException)
    end


    it 'allows items to be controlled by an agency other than the series controller' do
      series_control_agency =
        create(:json_agent_corporate_entity,
               :dates_of_existence => [{
                                         :label => 'existence',
                                         :date_type => 'range',
                                         :begin => '2019-01-01'
                                       }])

      item_control_agency =
        create(:json_agent_corporate_entity,
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


    it 'tells you who the responsible agency is for a record and aggregates them at series level' do
      item_override_agency =
        create(:json_agent_corporate_entity,
               :dates_of_existence => [{
                                         :label => 'existence',
                                         :date_type => 'range',
                                         :begin => '2019-01-01'
                                       }])

      override_controller = {
        :jsonmodel_type => 'series_system_agent_record_ownership_relationship',
        :relator => 'is_controlled_by',
        :start_date => '2019-02-01',
        :ref => item_override_agency.uri
      }

      series = create(:json_resource, :series_system_agent_relationships => [current_controller, old_controller])

      item_inheriting_control_from_series =
        create(:json_archival_object,
               :resource => { :ref => series.uri},
               :series_system_agent_relationships => [])

      item_overriding_control =
        create(:json_archival_object,
               :resource => { :ref => series.uri},
               :series_system_agent_relationships => [override_controller])

      item_inheriting_control_from_parent =
        create(:json_archival_object,
               :parent => { :ref => item_overriding_control.uri },
               :resource => { :ref => series.uri},
               :series_system_agent_relationships => [])

      Resource[series.id].responsible_agency.should eq(current_agency.uri)

      ArchivalObject[item_inheriting_control_from_series.id].responsible_agency.should eq(current_agency.uri)

      ArchivalObject[item_overriding_control.id].responsible_agency.should eq(item_override_agency.uri)

      ArchivalObject[item_inheriting_control_from_parent.id].responsible_agency.should eq(item_override_agency.uri)

      other_responsible_agencies = Resource[series.id].other_responsible_agencies

      other_responsible_agencies.length.should eq(1)

      other_responsible_agencies[item_overriding_control.id].should eq(item_override_agency.uri)
    end

    it 'tells you which agencies recently controlled a record' do
      date = (Time.now() - (60*60*24*50)).strftime('%Y-%m-%d')

      series = create(:json_resource, :series_system_agent_relationships => [current_controller.merge({:start_date => date}),
                                                                             old_controller.merge({:end_date => date})])

      Resource[series.id].recent_responsible_agencies.values.should eq([old_agency.uri])
    end
  end
end
