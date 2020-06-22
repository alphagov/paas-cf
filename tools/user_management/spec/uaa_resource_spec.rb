require "rest-client"
require "webmock/rspec"

require_relative "../lib/uaa_resource"

RSpec.describe UAAResource do
  let(:valid_resource) do
    {
      totalResults: 1,
      resources: [
        { id: "a-faked-guid" }
      ]
    }
  end

  let(:fake_uaa_client) { RestClient::Resource.new("http://fake-uaa.internal") }
  let(:uaa_resource) { UAAResource.new }

  it "sets @guid to nil by default" do
    expect(uaa_resource.guid).to be_nil
  end

  context "get" do
    it "raises an error when UAA returns unexpected status code" do
      stub_request(:get, "http://fake-uaa.internal/Resource/a-faked-resource")
        .to_return(status: 206, body: JSON.generate({}))

      expect { uaa_resource.get("/Resource/a-faked-resource", fake_uaa_client) }
        .to raise_error(Exception, /unexpected response fetching/)
    end

    it "raises an error when resource is not found" do
      stub_request(:get, "http://fake-uaa.internal/Resource/a-faked-resource")
        .to_return(status: 404, body: JSON.generate({}))

      expect { uaa_resource.get("/Resource/a-faked-resource", fake_uaa_client) }
        .to raise_error(Exception, /Not Found/)
    end

    it "raises error when insufficient data has been provided" do
      expect { uaa_resource.get("", nil) }.to raise_error(NoMethodError)
    end
  end

  context "get_resource" do
    it "sets @guid when getting the resource" do
      stub_request(:get, "http://fake-uaa.internal/Resource/a-faked-resource")
        .to_return(body: JSON.generate(valid_resource))

      uaa_resource.get_resource("/Resource/a-faked-resource", fake_uaa_client)
      expect(uaa_resource.guid).to eq("a-faked-guid")
    end

    it "raises an error when UAA returns zero resources" do
      stub_request(:get, "http://fake-uaa.internal/Resource/a-faked-resource")
        .to_return(body: JSON.generate(
          totalResults: 2,
        ))

      expect { uaa_resource.get_resource("/Resource/a-faked-resource", fake_uaa_client) }
        .to raise_error(Exception, /unexpected number of results fetching/)
    end

    it "raises an error when UAA returns more than one resource" do
      stub_request(:get, "http://fake-uaa.internal/Resource/a-faked-resource")
        .to_return(body: JSON.generate(
          totalResults: 0,
        ))

      expect { uaa_resource.get_resource("/Resource/a-faked-resource", fake_uaa_client) }
        .to raise_error(Exception, /unexpected number of results fetching/)
    end
  end
end
