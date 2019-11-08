require 'rest-client'
require 'webmock/rspec'

require_relative '../lib/uaa_resource'

RSpec.describe UAAResource do
  before do
    @fake_uaa_client = RestClient::Resource.new('http://fake-uaa.internal')

    @valid_resource = {
      resources: [{
        id: 'a-faked-guid'
      }],
      totalResults: 1
    }
  end

  it "sets @guid to nil by default" do
    uaa_resource = UAAResource.new
    expect(uaa_resource.guid).to be_nil
  end

  it 'raises error when insufficient data has been provided' do
    uaa_resource = UAAResource.new
    expect { uaa_resource.get_resource('', nil) }.to raise_error(NoMethodError)
  end

  it 'raises an error when UAA returns unexpected status code' do
    stub_request(:get, 'http://fake-uaa.internal/Resource/a-faked-resource')
      .to_return(status: 206, body: JSON.generate({}))

    uaa_resource = UAAResource.new
    expect { uaa_resource.get_resource('/Resource/a-faked-resource', @fake_uaa_client) }.to raise_error(Exception, /unexpected response fetching/)
  end

  it 'raises an error when resource is not found' do
    stub_request(:get, 'http://fake-uaa.internal/Resource/a-faked-resource')
      .to_return(status: 404, body: JSON.generate({}))

    uaa_resource = UAAResource.new
    expect { uaa_resource.get_resource('/Resource/a-faked-resource', @fake_uaa_client) }.to raise_error(Exception, /Not Found/)
  end

  it 'raises an error when UAA returns more or less resources than one' do
    stub_request(:get, 'http://fake-uaa.internal/Resource/a-faked-resource')
      .to_return(body: JSON.generate(
        totalResults: 2
      ))

    uaa_resource = UAAResource.new
    expect { uaa_resource.get_resource('/Resource/a-faked-resource', @fake_uaa_client) }.to raise_error(Exception, /unexpected number of results fetching/)

    stub_request(:get, 'http://fake-uaa.internal/Resource/a-faked-resource')
      .to_return(body: JSON.generate(
        totalResults: 0
      ))

    uaa_resource = UAAResource.new
    expect { uaa_resource.get_resource('/Resource/a-faked-resource', @fake_uaa_client) }.to raise_error(Exception, /unexpected number of results fetching/)
  end

  it "sets @guid when getting the resource" do
    stub_request(:get, 'http://fake-uaa.internal/Resource/a-faked-resource')
      .to_return(body: JSON.generate(@valid_resource))

    uaa_resource = UAAResource.new
    uaa_resource.get_resource('/Resource/a-faked-resource', @fake_uaa_client)
    expect(uaa_resource.guid).to eq('a-faked-guid')
  end
end
