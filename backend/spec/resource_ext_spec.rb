require_relative './factories_ext'
require 'spec_helper'

describe 'series_system resource_ext' do
  describe 'related functions' do
    it 'Should create and return function correctly' do
      resource = nil
      function = create(:json_function, {})
      opts = {
        functions: [{
          ref: function.uri
        }]
      }
      expect { resource = create(:json_resource, opts) }.to_not raise_error
      expect JSONModel(:resource).find(resource.id).functions.length.should eq(1)
    end

    it 'Should be able to add a function to an existing resource' do
      resource = create(:json_resource, {})
      function = create(:json_function, {})
      resource.functions = [{ ref: function.uri }]
      expect { resource.save }.to_not raise_error
      expect JSONModel(:resource).find(resource.id).functions.length.should eq(1)
    end

    it 'Should remove the function relation correctly' do
      resource = create(:json_resource, {})
      function = create(:json_function, {})
      resource.functions.push(ref: function.uri)
      resource.save
      resource.functions = []
      expect { resource.save }.to_not raise_error
      expect JSONModel(:resource).find(resource.id).functions.length.should eq(0)
    end

    it 'Should clean up the relationship when the function is deleted' do
      function = create(:json_function, {})
      opts = { functions: [{ ref: function.uri }] }
      resource = create(:json_resource, opts)
      expect JSONModel(:resource).find(resource.id).functions.length.should eq(1)
      expect { function.delete }.to_not raise_error
      expect JSONModel(:resource).find(resource.id).functions.length.should eq(0)
    end
  end

  describe 'related mandates' do
    it 'Should create and return mandate correctly' do
      resource = nil
      mandate = create(:json_mandate, {})
      opts = {
        mandates: [{
          ref: mandate.uri
        }]
      }
      expect { resource = create(:json_resource, opts) }.to_not raise_error
      expect JSONModel(:resource).find(resource.id).mandates.length.should eq(1)
    end

    it 'Should be able to add a mandate to an existing resource' do
      resource = create(:json_resource, {})
      mandate = create(:json_mandate, {})
      resource.mandates = [{ ref: mandate.uri }]
      expect { resource.save }.to_not raise_error
      expect JSONModel(:resource).find(resource.id).mandates.length.should eq(1)
    end

    it 'Should remove the mandate relation correctly' do
      resource = create(:json_resource, {})
      mandate = create(:json_mandate, {})
      resource.mandates.push(ref: mandate.uri)
      resource.save
      resource.mandates = []
      expect { resource.save }.to_not raise_error
      expect JSONModel(:resource).find(resource.id).mandates.length.should eq(0)
    end

    it 'Should clean up the relationship when the mandate is deleted' do
      mandate = create(:json_mandate, {})
      opts = { mandates: [{ ref: mandate.uri }] }
      resource = create(:json_resource, opts)
      expect JSONModel(:resource).find(resource.id).mandates.length.should eq(1)
      mandate.delete
      expect JSONModel(:resource).find(resource.id).mandates.length.should eq(0)
    end
  end

end
