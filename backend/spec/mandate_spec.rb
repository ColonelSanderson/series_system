require_relative './factories_ext'
require 'spec_helper'

describe 'series_system mandate controller' do
  def create_mandate(opts = {})
    create(:json_mandate, opts)
  end

  it 'lets you create a mandate and get it back' do
    opts = { title: 'Function title' }
    mandate = create_mandate(opts)
    JSONModel(:mandate).find(mandate.id).title.should eq(opts[:title])
  end

  it 'throws an error when `end_date` < `start_date`' do
    opts = { end_date: generate(:incremental_date),
             start_date: generate(:incremental_date) }
    expect { create_mandate(opts) }.to raise_error(JSONModel::ValidationException)
  end

  it 'does not let you create a mandate without a identifier' do
    opts = { identifier: nil }
    expect { create_mandate(opts) }.to raise_error(JSONModel::ValidationException)
  end

  it 'does not let you create a mandate without a title' do
    opts = { title: nil }
    expect { create_mandate(opts) }.to raise_error(JSONModel::ValidationException)
  end

  it "doesn't let you create a mandate without a start_date" do
    opts = { start_date: nil }
    expect { create_mandate(opts) }.to raise_error(JSONModel::ValidationException)
  end

  it "doesn't let you create a mandate without a mandate_type" do
    opts = { mandate_type: nil }
    expect { create_mandate(opts) }.to raise_error(JSONModel::ValidationException)
  end

  it 'lets you update a mandate' do
    mandate = create_mandate({})
    mandate.title = 'updated mandate'
    mandate.save
    JSONModel(:mandate).find(mandate.id).title.should eq('updated mandate')
  end

  it 'lets you create a mandate with an `external_document`' do
    opts = {
      external_documents: [{ title: generate(:generic_title),
                             location: generate(:string) }]
    }
    mandate = create_mandate(opts)
    JSONModel(:mandate).find(mandate.id).external_documents.length.should eq(1)
  end

  it 'lets you create a mandate with a function' do
    function = create(:json_function, {})
    mandate = nil
    opts = { functions: [{ ref: function.uri }] }
    expect { mandate = create_mandate(opts) }.to_not raise_error
    JSONModel(:mandate).find(mandate.id).functions.length.should eq(1)
  end

  it 'can give a list of all mandates' do
    mandate_names = ['mandate 1', 'mandate 2', 'mandate 3']
    mandate_names.each do |f|
      create_mandate(title: f)
    end
    mandates = JSONModel(:mandate).all(page: 1)['results']
    mandates.any? { |res| res.title == generate(:generic_title) }.should eq(false)

    mandate_names.each do |f|
      mandates.any? { |res| res.title == f }.should eq(true)
    end
  end

  it 'deletes the mandate correctly' do
    mandate = create_mandate({})
    mandate_id = mandate.id
    JSONModel(:mandate).find(mandate_id).id.should eq(mandate_id)
    expect { mandate.delete }.to_not raise_error
    expect { JSONModel(:mandate).find(mandate.id) }.to raise_error(RecordNotFound)
  end

  it 'Should successfully create and return a mandate with a location' do
    opts = {
      location: {
        ref: create(:json_location).uri
      }
    }
    mandate = create_mandate(opts)
    expect(JSONModel(:mandate).find(mandate.id)[:location]).to include("ref" => opts[:location][:ref])
  end
end
