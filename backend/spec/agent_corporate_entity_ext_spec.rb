require_relative './factories_ext'
require 'spec_helper'

describe 'series_system agent_corporate_entity_ext' do
  describe 'related functions' do
    it 'Should create and return function correctly' do
      agent = nil
      function = create(:json_function, {})
      opts = {
        functions: [{
          ref: function.uri
        }]
      }
      expect { agent = create(:json_agent_corporate_entity, opts) }.to_not raise_error
      expect JSONModel(:agent_corporate_entity).find(agent.id).functions.length.should eq(1)
    end

    it 'Should be able to add a function to an existing agent' do
      agent = create(:json_agent_corporate_entity, {})
      function = create(:json_function, {})
      agent.functions = [{ ref: function.uri }]
      expect { agent.save }.to_not raise_error
      expect JSONModel(:agent_corporate_entity).find(agent.id).functions.length.should eq(1)
    end

    it 'Should remove the function relation correctly' do
      agent = create(:json_agent_corporate_entity, {})
      function = create(:json_function, {})
      agent.functions.push(ref: function.uri)
      agent.save
      agent.functions = []
      expect { agent.save }.to_not raise_error
      expect JSONModel(:agent_corporate_entity).find(agent.id).functions.length.should eq(0)
    end

    it 'Should clean up the relationship when the function is deleted' do
      function = create(:json_function, {})
      opts = { functions: [{ ref: function.uri }] }
      agent = create(:json_agent_corporate_entity, opts)
      expect JSONModel(:agent_corporate_entity).find(agent.id).functions.length.should eq(1)
      function.delete
      expect JSONModel(:agent_corporate_entity).find(agent.id).functions.length.should eq(0)
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
      expect { agent = create(:json_agent_corporate_entity, opts) }.to_not raise_error
      expect JSONModel(:agent_corporate_entity).find(agent.id).mandates.length.should eq(1)
    end

    it 'Should be able to add a mandate to an existing agent' do
      agent = create(:json_agent_corporate_entity, {})
      mandate = create(:json_mandate, {})
      agent.mandates = [{ ref: mandate.uri }]
      expect { agent.save }.to_not raise_error
      expect JSONModel(:agent_corporate_entity).find(agent.id).mandates.length.should eq(1)
    end

    it 'Should remove the mandate relation correctly' do
      agent = create(:json_agent_corporate_entity, {})
      mandate = create(:json_mandate, {})
      agent.mandates.push(ref: mandate.uri)
      agent.save
      agent.mandates = []
      expect { agent.save }.to_not raise_error
      expect JSONModel(:agent_corporate_entity).find(agent.id).mandates.length.should eq(0)
    end

    it 'Should clean up the relationship when the mandate is deleted' do
      mandate = create(:json_mandate, {})
      opts = { mandates: [{ ref: mandate.uri }] }
      agent = create(:json_agent_corporate_entity, opts)
      expect JSONModel(:agent_corporate_entity).find(agent.id).mandates.length.should eq(1)
      mandate.delete
      expect JSONModel(:agent_corporate_entity).find(agent.id).mandates.length.should eq(0)
    end
  end


  describe 'agency categories' do

    it 'allows an agent corporate to be created with a category' do
      agent = create(:json_agent_corporate_entity,
                     :agency_category => 'LOC')

      expect JSONModel(:agent_corporate_entity).find(agent.id).agency_category.should eq('LOC')
    end

  end


end
