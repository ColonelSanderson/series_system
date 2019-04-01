require 'spec_helper'


describe 'series_system mandate model' do
  it 'lets you create a mandate' do
    opts = { title: 'Function title' }
    mandate = Mandate.create_from_json(build(:json_mandate, opts))
    Mandate[mandate.id].title.should eq(opts[:title])
  end

  it 'does not let you create a mandate without a title' do
    opts = { title: nil }
    expect { Mandate.create_from_json(build(:json_mandate, opts)) }.to raise_error(JSONModel::ValidationException)
  end

  it "doesn't let you create a mandate without a mandate_type" do
    opts = { mandate_type: nil }
    expect { Mandate.create_from_json(build(:json_mandate, opts)) }.to raise_error(JSONModel::ValidationException)
  end

  it 'lets you create a mandate without a date' do
    opts = { date: nil }
    expect { Mandate.create_from_json(build(:json_mandate, opts)) }.to_not raise_error
  end
end


describe 'series_system mandate controller' do
  def create_mandate(opts = {})
    create(:json_mandate, opts)
  end

  it 'lets you create a mandate and get it back' do
    opts = { title: 'Function title' }
    mandate = create_mandate(opts)
    JSONModel(:mandate).find(mandate.id).title.should eq(opts[:title])
  end

  it 'lets you update a mandate' do
    mandate = create_mandate({})
    mandate.title = 'updated mandate'
    mandate.save
    JSONModel(:mandate).find(mandate.id).title.should eq('updated mandate')
  end

  it 'lets you create a mandate with an external id' do
    mandate = nil
    opts = { external_ids: [{ external_id: "dummyid", source: 'dummysource' }] }
    expect { mandate = create_mandate(opts) }.to_not raise_error
    JSONModel(:mandate).find(mandate.id).external_ids.length.should eq(1)
    external_id = JSONModel(:mandate).find(mandate.id).external_ids.first
    external_id['external_id'].should eq(opts[:external_ids][0][:external_id])
    external_id['source'].should eq(opts[:external_ids][0][:source])
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

end
