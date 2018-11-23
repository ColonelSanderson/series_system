require_relative './factories_ext'
require 'spec_helper'

describe 'Function controller' do
  def create_function(opts = {})
    create(:json_function, opts)
  end

  it 'lets you create a function and get it back' do
    opts = { title: 'Function title' }
    function = create_function(opts)
    JSONModel(:function).find(function.id).title.should eq(opts[:title])
  end

  it 'throws an error when `end_date` < `start_date`' do
    opts = { end_date: generate(:incremental_date),
             start_date: generate(:incremental_date) }
    expect { create_function(opts) }.to raise_error(JSONModel::ValidationException)
  end

  it 'does not let you create a function without a identifier' do
    opts = { identifier: nil }
    expect { create_function(opts) }.to raise_error(JSONModel::ValidationException)
  end

  it 'does not let you create a function without a title' do
    opts = { title: nil }
    expect { create_function(opts) }.to raise_error(JSONModel::ValidationException)
  end

  it "doesn't let you create a function without a start_date" do
    opts = { start_date: nil }
    expect { create_function(opts) }.to raise_error(JSONModel::ValidationException)
  end

  it 'lets you update a function' do
    function = create_function({})
    function.title = 'updated function'
    function.save
    JSONModel(:function).find(function.id).title.should eq('updated function')
  end

  it 'lets you create a function with an `external_document`' do
    opts = {
      external_documents: [{ title: generate(:generic_title),
                             location: generate(:string) }]
    }
    function = create_function(opts)
    JSONModel(:function).find(function.id).external_documents.length.should eq(1)
  end

  it 'lets you create a function with a linked agent' do
    function = nil
    opts = {
      linked_agents: [{
        ref: create(:json_agent_corporate_entity).uri
      }]
    }
    expect { function = create_function(opts) }.to_not raise_error
    JSONModel(:function).find(function.id).linked_agents.length.should eq(1)
  end

  it 'lets you create a function with a mandate' do
    mandate = create(:json_mandate, {})
    function = nil
    opts = { mandates: [{ ref: mandate.uri }] }
    expect { function = create_function(opts) }.to_not raise_error
    JSONModel(:function).find(function.id).mandates.length.should eq(1)
  end

  it 'can give a list of all functions' do
    function_names = ['function 1', 'function 2', 'function 3']
    function_names.each do |f|
      create_function(title: f)
    end
    functions = JSONModel(:function).all(page: 1)['results']
    functions.any? { |res| res.title == generate(:generic_title) }.should eq(false)

    function_names.each do |f|
      functions.any? { |res| res.title == f }.should eq(true)
    end
  end

  it 'deletes the function correctly' do
    function = create_function({})
    function_id = function.id
    JSONModel(:function).find(function_id).id.should eq(function_id)
    expect { function.delete }.to_not raise_error
    expect { JSONModel(:function).find(function.id) }.to raise_error(RecordNotFound)
  end
end
