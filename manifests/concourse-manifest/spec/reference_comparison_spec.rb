require 'open3'

def merge_fixtures(fixtures)
  final = {}
  fixtures.each do |fixture|
    new_fixture = YAML.load_file(File.expand_path(fixture, __FILE__))
    final.merge!(new_fixture) { |_key, a_val, b_val| a_val.merge b_val }
  end
  final
end

RSpec.describe "manifest generation" do
  let(:fixtures) {
    merge_fixtures [
      "../fixtures/concourse-terraform-outputs.yml",
      "../fixtures/generated-concourse-secrets.yml",
      "../fixtures/predefined-concourse-secrets.yml",
      "../fixtures/vpc-terraform-outputs.yml",
    ]
  }

  it "gets values from vpc terraform outputs" do
    expect(
      manifest_with_defaults["resource_pools"].first["cloud_properties"]["availability_zone"]
    ).to eq(fixtures["terraform_outputs"]["zone0"])
  end

  it "gets values from concourse terraform outputs" do
    expect(
      manifest_with_defaults["jobs"].first["properties"]["external_url"]
    ).to eq("https://" + fixtures["terraform_outputs"]["concourse_dns_name"])
  end

  it "gets values from generated secrets" do
    fixture_nats_password = fixtures["secrets"]["concourse_nats_password"]

    expect(
      manifest_with_defaults["cloud_provider"]["properties"]["agent"]["mbus"]
    ).to eq("https://mbus:#{fixture_nats_password}@0.0.0.0:6868")
  end

  it "gets values from predefined secrets" do
    expect(
      manifest_with_defaults["jobs"].first["properties"]["basic_auth_password"]
    ).to eq(fixtures["secrets"]["concourse_atc_password"])
  end
end
