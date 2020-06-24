RSpec.describe "Tenant UAA clients" do
  let(:manifest) { manifest_with_defaults }
  let(:properties) { manifest.fetch("instance_groups.uaa.jobs.uaa.properties") }

  it "creates a new UAA client for each entry in the deployment env config" do
    uaa_clients = properties.fetch("uaa").fetch("clients")
    expect(uaa_clients["dev-uaa-client"]).not_to be_nil
  end

  it "does not create new UAA clients for entries not in the deployment env config" do
    uaa_clients = properties.fetch("uaa").fetch("clients")
    expect(uaa_clients["prod-lon-uaa-client"]).to be_nil
  end

  it "creates secrets for the UAA clients it creates" do
    variables = manifest.fetch("variables")
    expect(variables.any? do |var|
      var["name"] == "secrets_dev_uaa_client"
    end).to be true
  end
end
