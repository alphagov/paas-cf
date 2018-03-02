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

  describe "in order to ensure high availability of ingestor" do
    it "has ingestor serial" do
      expect("ingestor_z1").to be_updated_serially
      expect("ingestor_z2").to be_updated_serially
    end
  end

  describe "in order to start one consul master for consensus" do
    it "has consul serial" do
      expect("consul").to be_updated_serially
    end

    specify "has consul first" do
      expect(instance_groups[0]["name"]).to eq("consul")
    end
  end

  describe "in order to apply BBS migrations before upgrading the cells" do
    it "has database before the cells" do
      expect("diego-api").to be_ordered_before("cell")
    end

    it "has database serial" do
      expect("diego-api").to be_updated_serially
    end
  end

  describe "in order to match the upstream Diego instance_group ordering" do
    it "has database before brain" do
      expect("diego-api").to be_ordered_before("brain")
    end

    it "has brain before the cells" do
      expect("brain").to be_ordered_before("cell")
    end

    it "has the cells before cc_bridge" do
      expect("cell").to be_ordered_before("cc_bridge")
    end

    it "has cc_bridge before route_emitter" do
      expect("cc_bridge").to be_ordered_before("route_emitter")
    end

    it "has route_emitter before access" do
      expect("route_emitter").to be_ordered_before("access")
    end
  end

  it "should list consul_agent first if present" do
    instance_groups_with_consul = instance_groups.reject { |i|
      i["jobs"].select { |j|
        j["name"] == "consul_agent"
      }.empty?
    }

    instance_groups_with_consul.each { |i|
      expect(i["jobs"].first["name"]).to eq("consul_agent"),
        "expected '#{i['name']}' instance_group to list 'consul_agent' first"
    }
  end
end

RSpec.describe "uaa instance_group" do
  let(:instance_groups) { manifest_with_defaults.fetch("instance_groups") }

  describe "common instance_group properties" do
    instance_group_name = "uaa"
    context "instance_group #{instance_group_name}" do
      subject(:instance_group) { instance_groups.find { |i| i["name"] == instance_group_name } }

      describe "route registrar" do
        let(:routes) { instance_group.fetch("properties").fetch("route_registrar").fetch("routes") }

        it "registers the correct uris" do
          expect(routes.length).to eq(1)
          expect(routes.first.fetch('uris')).to match_array([
            "uaa.#{terraform_fixture(:cf_root_domain)}",
            "login.#{terraform_fixture(:cf_root_domain)}",
          ])
        end
      end
    end
  end
end
