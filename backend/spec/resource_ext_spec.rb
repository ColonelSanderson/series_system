require_relative './factories_ext'
require 'spec_helper'

describe 'series_system resource_ext' do
  describe 'related functions' do
    xit 'Should create and return function correctly' do
      agent = nil
      function = create(:json_function, {})
      opts = {
        functions: [{
          ref: function.uri
        }]
      }
      expect { agent = create(:json_resource, opts) }.to_not raise_error
      expect JSONModel(:resource).find(agent.id).functions.length.should eq(1)
      expect JSONModel(:function).find(function.id).linked_agents.length.should eq(0)
    end

    xit 'Should be able to add a function to an existing agent' do
      agent = create(:json_resource, {})
      function = create(:json_function, {})
      agent.functions = [{ ref: function.uri }]
      expect { agent.save }.to_not raise_error
      expect JSONModel(:resource).find(agent.id).functions.length.should eq(1)
    end

    xit 'Should remove the function relation correctly' do
      agent = create(:json_resource, {})
      function = create(:json_function, {})
      agent.functions.push(ref: function.uri)
      agent.save
      agent.functions = []
      expect { agent.save }.to_not raise_error
      expect JSONModel(:resource).find(agent.id).functions.length.should eq(0)
    end

    xit 'Should clean up the relationship when the function is deleted' do
      function = create(:json_function, {})
      opts = { functions: [{ ref: function.uri }] }
      agent = create(:json_resource, opts)
      expect JSONModel(:resource).find(agent.id).functions.length.should eq(1)
      function.delete
      expect JSONModel(:resource).find(agent.id).functions.length.should eq(0)
    end
  end

  describe 'related mandates' do
    xit 'Should create and return mandate correctly' do
      agent = nil
      mandate = create(:json_mandate, {})
      opts = {
        mandates: [{
          ref: mandate.uri
        }]
      }
      expect { agent = create(:json_resource, opts) }.to_not raise_error
      expect JSONModel(:resource).find(agent.id).mandates.length.should eq(1)
      expect JSONModel(:mandate).find(mandate.id).linked_agents.length.should eq(0)
    end

    xit 'Should be able to add a mandate to an existing agent' do
      agent = create(:json_resource, {})
      mandate = create(:json_mandate, {})
      agent.mandates = [{ ref: mandate.uri }]
      expect { agent.save }.to_not raise_error
      expect JSONModel(:resource).find(agent.id).mandates.length.should eq(1)
    end

    xit 'Should remove the mandate relation correctly' do
      agent = create(:json_resource, {})
      mandate = create(:json_mandate, {})
      agent.mandates.push(ref: mandate.uri)
      agent.save
      agent.mandates = []
      expect { agent.save }.to_not raise_error
      expect JSONModel(:resource).find(agent.id).mandates.length.should eq(0)
    end

    xit 'Should clean up the relationship when the mandate is deleted' do
      mandate = create(:json_mandate, {})
      opts = { mandates: [{ ref: mandate.uri }] }
      agent = create(:json_resource, opts)
      expect JSONModel(:resource).find(agent.id).mandates.length.should eq(1)
      mandate.delete
      expect JSONModel(:resource).find(agent.id).mandates.length.should eq(0)
    end
  end

  describe 'related controlled_by' do
    xit 'Should create and return controlled_by correctly' do
      resource = nil
      controlled_by = create(:json_agent_corporate_entity, {})
      opts = {
        controlled_by: [{ ref: controlled_by.uri }]
      }
      expect { resource = create(:json_resource, opts) }.to_not raise_error
      expect JSONModel(:resource).find(resource.id).controlled_by.length.should eq(1)
    end

    xit 'Should be able to add a controlled_by to an existing resource' do
      resource = create(:json_resource, {})
      controlled_by = create(:json_agent_corporate_entity, {})
      resource.controlled_by = [{ ref: controlled_by.uri }]
      expect { resource.save }.to_not raise_error
      expect JSONModel(:resource).find(resource.id).controlled_by.length.should eq(1)
    end

    xit 'Should remove the controlled_by relation correctly' do
      resource = create(:json_resource, {})
      controlled_by = create(:json_agent_corporate_entity, {})
      resource.controlled_by.push(ref: controlled_by.uri)
      resource.save
      resource.controlled_by = nil
      expect { resource.save }.to_not raise_error
      expect JSONModel(:resource).find(resource.id).controlled_by.length.should eq(0)
    end
  end
end