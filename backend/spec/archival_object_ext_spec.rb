require_relative './factories_ext'
require 'spec_helper'

describe 'series_system archival_object_ext' do
  describe 'related functions' do
    it 'Should create and return function correctly' do
      agent = nil
      function = create(:json_function, {})
      opts = {
        functions: [{
          ref: function.uri
        }]
      }
      expect { agent = create(:json_archival_object, opts) }.to_not raise_error
      expect JSONModel(:archival_object).find(agent.id).functions.length.should eq(1)
    end

    it 'Should be able to add a function to an existing agent' do
      agent = create(:json_archival_object, {})
      function = create(:json_function, {})
      agent.functions = [{ ref: function.uri }]
      expect { agent.save }.to_not raise_error
      expect JSONModel(:archival_object).find(agent.id).functions.length.should eq(1)
    end

    it 'Should remove the function relation correctly' do
      agent = create(:json_archival_object, {})
      function = create(:json_function, {})
      agent.functions.push(ref: function.uri)
      agent.save
      agent.functions = []
      expect { agent.save }.to_not raise_error
      expect JSONModel(:archival_object).find(agent.id).functions.length.should eq(0)
    end

    it 'Should clean up the relationship when the function is deleted' do
      function = create(:json_function, {})
      opts = { functions: [{ ref: function.uri }] }
      agent = create(:json_archival_object, opts)
      expect JSONModel(:archival_object).find(agent.id).functions.length.should eq(1)
      function.delete
      expect JSONModel(:archival_object).find(agent.id).functions.length.should eq(0)
    end
  end

  describe 'related mandates' do
    it 'Should create and return mandate correctly' do
      agent = nil
      mandate = create(:json_mandate, {})
      opts = {
        mandates: [{
          ref: mandate.uri
        }]
      }
      expect { agent = create(:json_archival_object, opts) }.to_not raise_error
      expect JSONModel(:archival_object).find(agent.id).mandates.length.should eq(1)
    end

    it 'Should be able to add a mandate to an existing agent' do
      agent = create(:json_archival_object, {})
      mandate = create(:json_mandate, {})
      agent.mandates = [{ ref: mandate.uri }]
      expect { agent.save }.to_not raise_error
      expect JSONModel(:archival_object).find(agent.id).mandates.length.should eq(1)
    end

    it 'Should remove the mandate relation correctly' do
      agent = create(:json_archival_object, {})
      mandate = create(:json_mandate, {})
      agent.mandates.push(ref: mandate.uri)
      agent.save
      agent.mandates = []
      expect { agent.save }.to_not raise_error
      expect JSONModel(:archival_object).find(agent.id).mandates.length.should eq(0)
    end

    it 'Should clean up the relationship when the mandate is deleted' do
      mandate = create(:json_mandate, {})
      opts = { mandates: [{ ref: mandate.uri }] }
      agent = create(:json_archival_object, opts)
      expect JSONModel(:archival_object).find(agent.id).mandates.length.should eq(1)
      mandate.delete
      expect JSONModel(:archival_object).find(agent.id).mandates.length.should eq(0)
    end
  end
end
