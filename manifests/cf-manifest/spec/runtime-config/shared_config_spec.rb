
RSpec.describe "Runtime config" do
  let(:runtime_config) { load_runtime_config }

  it "uses a shared collectd config file" do
    collectd_addon = runtime_config.fetch("addons").find { |addon| addon["name"] == "collectd" }
    expect(collectd_addon.fetch("properties").fetch("collectd").fetch("interval")).to eq 10
  end

  describe "in order to monitor all hosts via datadog" do
    let(:datadog_addon) { runtime_config.fetch("addons").find { |addon| addon["name"] == "datadog-agent" } }

    it "has datadog included with properties from shared config" do
      expect(datadog_addon.fetch("properties").fetch("use_dogstatsd")).to eq false
    end

    it "adds aws_account as a tag to datadog" do
      expect(datadog_addon.fetch("properties").fetch("tags")).not_to be_nil
      expect(datadog_addon.fetch("properties").fetch("tags").fetch("aws_account")).to eq(ENV["AWS_ACCOUNT"])
    end

    it "adds deploy_env from the terraform environment as a tag to datadog" do
      expect(datadog_addon.fetch("properties").fetch("tags")).not_to be_nil
      terraform_environment = terraform_fixture("environment")
      expect(datadog_addon.fetch("properties").fetch("tags").fetch("deploy_env")).to eq(terraform_environment)
    end
  end

  it "has syslog_forwarder configured with the address from terraform output" do
    syslog_forwarder_addon = runtime_config.fetch("addons").find { |addon| addon["name"] == "syslog_forwarder" }
    syslog_forwarder_address = syslog_forwarder_addon.fetch("properties").fetch("syslog").fetch("address")

    expect(syslog_forwarder_address).to eq terraform_fixture("logsearch_ingestor_elb_dns_name")
  end
end
