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

  it 'lets you create a function with non preferred names' do
    opts = { non_preferred_names: [{name: 'Bob'}, {name: 'Mary'}] }
    function = Function.create_from_json(build(:json_function, opts))
    names = Function[function.id].function_non_preferred_name
    names.length.should be(2)
    names[0].name.should eq("Bob")
    names[1].name.should eq("Mary")
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
