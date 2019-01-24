require_relative './factories_ext'
require 'spec_helper'

describe 'series_system function model' do

  it 'does not let you create a function without a title' do
    opts = { title: nil }
    expect { Function.create_from_json(build(:json_function, opts)) }.to raise_error(JSONModel::ValidationException)
  end

  it 'lets you create a function without a date' do
    opts = { date: nil }
    expect { Function.create_from_json(build(:json_function, opts)) }.to_not raise_error
  end

end


describe 'series_system function controller' do

  def create_function(opts = {})
    create(:json_function, opts)
  end

  it 'lets you create a function and get it back' do
    opts = { title: 'Function title' }
    function = create_function(opts)
    JSONModel(:function).find(function.id).title.should eq(opts[:title])
  end

  it 'lets you update a function' do
    function = create_function({})
    function.title = 'updated function'
    function.save
    JSONModel(:function).find(function.id).title.should eq('updated function')
  end

  it 'lets you create a function with a mandate' do
    mandate = create(:json_mandate, {})
    function = nil
    opts = { mandates: [{ ref: mandate.uri }] }
    expect { function = create_function(opts) }.to_not raise_error
    JSONModel(:function).find(function.id).mandates.length.should eq(1)
    JSONModel(:mandate).find(mandate.id).functions.length.should eq(1)
  end

  it 'lets you link a function as a synonym of another function' do
    function_a = create(:json_function, {})
    function_b = create(:json_function, {})

    relationship = JSONModel(:function_synonym_relationship).new
    relationship.ref = function_b.uri
    relationship.relator = 'is_synonym_of'

    function_a.related_functions = [ relationship.to_hash ]
    expect { function_a.save }.to_not raise_error

    JSONModel(:function).find(function_a.id).related_functions.length.should eq(1)
    JSONModel(:function).find(function_a.id).related_functions.first['relator'].should eq('is_synonym_of')
    JSONModel(:function).find(function_a.id).related_functions.first['ref'].should eq(function_b.uri)
    JSONModel(:function).find(function_b.id).related_functions.length.should eq(1)
    JSONModel(:function).find(function_b.id).related_functions.first['relator'].should eq('is_synonym_of')
    JSONModel(:function).find(function_b.id).related_functions.first['ref'].should eq(function_a.uri)
  end

  it 'lets you link a function as a preferred term of another function' do
    function_a = create(:json_function, {})
    function_b = create(:json_function, {})

    relationship = JSONModel(:function_preferred_term_relationship).new
    relationship.ref = function_b.uri
    relationship.relator = 'has_preferred_term_of'

    function_a.related_functions = [ relationship.to_hash ]
    expect { function_a.save }.to_not raise_error

    JSONModel(:function).find(function_a.id).related_functions.length.should eq(1)
    JSONModel(:function).find(function_a.id).related_functions.first['relator'].should eq('has_preferred_term_of')
    JSONModel(:function).find(function_a.id).related_functions.first['ref'].should eq(function_b.uri)
    JSONModel(:function).find(function_b.id).related_functions.length.should eq(1)
    JSONModel(:function).find(function_b.id).related_functions.first['relator'].should eq('is_preferred_term_of')
    JSONModel(:function).find(function_b.id).related_functions.first['ref'].should eq(function_a.uri)
  end

  it 'lets you link a function as a non-preferred term of another function' do
    function_a = create(:json_function, {})
    function_b = create(:json_function, {})

    relationship = JSONModel(:function_nonpreferred_term_relationship).new
    relationship.ref = function_b.uri
    relationship.relator = 'has_nonpreferred_term_of'

    function_a.related_functions = [ relationship.to_hash ]
    expect { function_a.save }.to_not raise_error

    JSONModel(:function).find(function_a.id).related_functions.length.should eq(1)
    JSONModel(:function).find(function_a.id).related_functions.first['relator'].should eq('has_nonpreferred_term_of')
    JSONModel(:function).find(function_a.id).related_functions.first['ref'].should eq(function_b.uri)
    JSONModel(:function).find(function_b.id).related_functions.length.should eq(1)
    JSONModel(:function).find(function_b.id).related_functions.first['relator'].should eq('is_nonpreferred_term_of')
    JSONModel(:function).find(function_b.id).related_functions.first['ref'].should eq(function_a.uri)
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

  it 'deletes the function correctly when linked to a mandate' do
    mandate = create(:json_mandate, {})
    function = create_function({ mandates: [{ ref: mandate.uri }] })
    function_id = function.id
    JSONModel(:function).find(function_id).id.should eq(function_id)
    JSONModel(:mandate).find(mandate.id).functions.should_not be_empty
    expect { function.delete }.to_not raise_error
    expect { JSONModel(:function).find(function.id) }.to raise_error(RecordNotFound)
    JSONModel(:mandate).find(mandate.id).functions.should be_empty
  end
end
