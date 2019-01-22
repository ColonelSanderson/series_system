require_relative './factories_ext'
require 'spec_helper'

describe 'series_system location controller' do
  xit 'Should not allow the attachment of multiple locations to a single object' do
    opts = {
      location: [
        { ref: create(:json_location).uri },
        { ref: create(:json_location).uri }
      ]
    }
    expect { create(:json_function, opts) }.to raise_error(JSONModel::ValidationException)
    expect { create(:json_mandate, opts) }.to raise_error(JSONModel::ValidationException)
  end
end