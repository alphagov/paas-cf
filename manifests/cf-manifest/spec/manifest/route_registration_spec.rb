RSpec.describe "registration of routes for services behind GoRouter" do
  let(:uaa_routes) do
    manifest_with_defaults.fetch("instance_groups.uaa.jobs.route_registrar.properties.route_registrar.routes")
  end
  let(:api_routes) do
    manifest_with_defaults.fetch("instance_groups.api.jobs.route_registrar.properties.route_registrar.routes")
  end

  it "registers the correct uris for uaa" do
    expect(uaa_routes.length).to eq(1)
    expect(uaa_routes.first.fetch("uris")).to match_array([
      "uaa.#{terraform_fixture_value(:cf_root_domain)}",
      "login.#{terraform_fixture_value(:cf_root_domain)}",
    ])
  end

  it "registers the correct uris for api" do
    expect(api_routes.length).to eq(2)
    expect(api_routes[0].fetch("uris")).to match_array([
      "api.#{terraform_fixture_value(:cf_root_domain)}",
    ])
    expect(api_routes[1].fetch("uris")).to match_array([
      "api.#{terraform_fixture_value(:cf_root_domain)}/networking",
    ])
  end
end
