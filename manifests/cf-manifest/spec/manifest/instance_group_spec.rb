RSpec.describe "the global update block" do
  let(:manifest) { manifest_with_defaults }

  describe "in order to run parallel deployment by default" do
    it "has serial false" do
      expect(manifest["update"]["serial"]).to be false
    end
  end
end

RSpec.describe "the instance_groups definitions block" do
  let(:instance_groups) { manifest_with_defaults["instance_groups"] }

  def get_instance_group(instance_group_name)
    instance_group = instance_groups.select { |i| i["name"] == instance_group_name }.first
    if instance_group == nil
      raise "No instance_group named '#{instance_group_name}' known. Known instance_groups are #{instance_groups.collect { |ig_hash| ig_hash['name'] }}"
    else
      instance_group
    end
  end

  matcher :be_updated_serially do
    match do |instance_group_name|
      get_instance_group(instance_group_name)["update"]["serial"]
    end
  end

  matcher :be_ordered_before do |later_instance_group_name|
    match do |earlier_instance_group_name|
      later_instance_group = get_instance_group(later_instance_group_name)
      earlier_instance_group = get_instance_group(earlier_instance_group_name)
      instance_groups.index { |i| i == earlier_instance_group } < instance_groups.index { |i| i == later_instance_group }
    end
  end

  describe "in order to apply BBS migrations before upgrading the diego-cells" do
    it "has diego-api before the cells" do
      expect("diego-api").to be_ordered_before("diego-cell")
    end
  end

  describe "in order to match the upstream Diego instance_group ordering" do
    it "has diego-api before scheduler" do
      expect("diego-api").to be_ordered_before("scheduler")
    end

    it "has scheduler before the diego cells" do
      expect("scheduler").to be_ordered_before("diego-cell")
    end

    it "has api before scheduler" do
      expect("api").to be_ordered_before("scheduler")
    end
  end

  specify "all instance_groups have a bosh password set" do
    missing = []
    instance_groups.each do |ig|
      pw = ig.dig("env", "bosh", "password")
      missing << ig['name'] if pw.nil? || pw.empty?
    end
    expect(missing).to be_empty,
      "Expected instance_groups #{missing.inspect} to have env.bosh.password set"
  end
end

RSpec.describe "registration of routes for services behind GoRouter" do
  let(:uaa_routes) {
    manifest_with_defaults.fetch("instance_groups.uaa.jobs.route_registrar.properties.route_registrar.routes")
  }
  let(:api_routes) {
    manifest_with_defaults.fetch("instance_groups.api.jobs.route_registrar.properties.route_registrar.routes")
  }

  it "registers the correct uris for uaa" do
    expect(uaa_routes.length).to eq(1)
    expect(uaa_routes.first.fetch('uris')).to match_array([
      "uaa.#{terraform_fixture_value(:cf_root_domain)}",
      "login.#{terraform_fixture_value(:cf_root_domain)}",
    ])
  end

  it "registers the correct uris for api" do
    expect(api_routes.length).to eq(2)
    expect(api_routes[0].fetch('uris')).to match_array([
      "api.#{terraform_fixture_value(:cf_root_domain)}",
    ])
    expect(api_routes[1].fetch('uris')).to match_array([
      "api.#{terraform_fixture_value(:cf_root_domain)}/networking",
    ])
  end
end
