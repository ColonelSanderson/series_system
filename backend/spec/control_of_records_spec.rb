require 'spec_helper'

describe 'Series System' do

  describe 'Control of Records' do

    it 'ensures an item has exactly one controlling agency' do
      # series must have 1 current series_system_agent_record_ownership_relationship to a current agency
      agent = create(:json_agent_corporate_entity,
                     :dates_of_existence => [{
                                               :label => 'existence',
                                               :date_type => 'range',
                                               :begin => '2019-01-01'
                                             }])

      expect { create(:json_resource) }.to raise_error(JSONModel::ValidationException)
    end

    it 'does not allow terminated agencies to control records' do
    end

    it 'does not allow dates of control to overlap for an item' do
    end

    it 'ensures control relationships have a start date' do
    end

  end
end
