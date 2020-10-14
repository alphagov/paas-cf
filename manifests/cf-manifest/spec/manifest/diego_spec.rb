RSpec.describe "diego" do
  describe "rep" do
    let(:manifest) { manifest_with_defaults }
    let(:properties) { manifest.fetch("instance_groups.diego-cell.jobs.rep.properties") }

    it "has containers configured" do
      expect(properties.dig("containers")).not_to be_nil
    end

    it "has containers/proxy enabled" do
      expect(properties.dig("containers", "proxy", "enabled")).to be(true)
    end
  end

  describe "api instance" do
    subject(:instance) { manifest.fetch("instance_groups.diego-api") }

    let(:manifest) { manifest_with_defaults }

    it_behaves_like "a cf rds client"
  end

  describe "silk-cni" do
    let(:silk_cni) { manifest_with_defaults.fetch("instance_groups.diego-cell.jobs.silk-cni") }
    let(:silk_cni_props) { manifest_with_defaults.fetch("instance_groups.diego-cell.jobs.silk-cni.properties") }

    it "overrides the vpa bosh link" do
      expect(silk_cni.dig("consumes", "vpa")).to eq("from" => "vpa-default")
    end
  end

  describe "silk-daemon" do
    let(:silk_daemon) { manifest_with_defaults.fetch("instance_groups.diego-cell.jobs.silk-daemon") }

    it "overrides the vpa bosh link" do
      expect(silk_daemon.dig("consumes", "vpa")).to eq("from" => "vpa-default")
    end
  end

  describe "vxlan-policy-agent" do
    let(:vxlan_policy_agent) { manifest_with_defaults.fetch("instance_groups.diego-cell.jobs.vxlan-policy-agent") }

    it "overrides the vpa bosh link" do
      expect(vxlan_policy_agent.dig("provides", "vpa")).to eq("as" => "vpa-default")
    end
  end
end
