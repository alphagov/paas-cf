require "base64"
require "json"
require "ostruct"

RSpec.describe TenantNotifier do
  let(:notify_api_key) { "we-are-mocking-this" }
  let(:org_name) { "example-org" }
  let(:tenant_email_address) { "org-manager@domain.tld" }

  let(:service_instances) do
    [
      OpenStruct.new(
        org_name: org_name,
        space_name: "a-space",
        instance_name: "an-instance",
      ),
      OpenStruct.new(
        org_name: org_name,
        space_name: "another-space",
        instance_name: "another-instance",
      ),
    ]
  end

  let(:maintenance_window_date) { "2038/01/19" }
  let(:maintenance_window_time_range) { "2000-2100" }

  let(:alt_maintenance_window_date) { "2038/01/19" }
  let(:alt_maintenance_window_time_range) { "2000-2100" }

  context "when generating an email" do
    let(:contents) do
      TenantNotifier.new(notify_api_key).generate_email_contents(
        org_name: org_name,
        service_instances: service_instances,
        maintenance_window_date: maintenance_window_date,
        maintenance_window_time_range: maintenance_window_time_range,
        alt_maintenance_window_date: alt_maintenance_window_date,
        alt_maintenance_window_time_range: alt_maintenance_window_time_range,
        region: "London"
      )
    end

    it "should list the service instances to be updated" do
      expect(contents).to match("( Org / Space / Service )")

      expect(contents).to match([
        service_instances.first.org_name,
        service_instances.first.space_name,
        service_instances.first.instance_name,
      ].join(" / "))

      expect(contents).to match([
        service_instances.last.org_name,
        service_instances.last.space_name,
        service_instances.last.instance_name,
      ].join(" / "))
    end

    it "should include the maintenance window" do
      expect(contents).to match(
        "on #{maintenance_window_date}, between #{maintenance_window_time_range}",
      )
    end

    it "should include the alternative maintenance window" do
      expect(contents).to match(
        "on #{alt_maintenance_window_date}, between #{alt_maintenance_window_time_range}",
      )
    end

    it "should include the region" do
      expect(contents).to match(
        "(London)",
      )
    end
  end

  context "when notifying a tenant" do
    let(:notifier) { TenantNotifier.new(notify_api_key) }

    before(:each) do
      notifier.instance_variable_set(:@client, double)
      allow(notifier.client).to receive(:send_email)
    end

    let(:send_email) do
      notifier.notify_tenant(
        tenant_email_address: tenant_email_address,
        org_name: org_name,
        service_instances: service_instances,
        maintenance_window_date: maintenance_window_date,
        maintenance_window_time_range: maintenance_window_time_range,
        alt_maintenance_window_date: alt_maintenance_window_date,
        alt_maintenance_window_time_range: alt_maintenance_window_time_range,
        region: "London"
      )
    end

    it 'should personalise the Notify "contents" field ' do
      expect(notifier.client).to receive(:send_email).with(
        hash_including(personalisation: hash_including(
          contents: TenantNotifier.new(notify_api_key).generate_email_contents(
            org_name: org_name,
            service_instances: service_instances,
            maintenance_window_date: maintenance_window_date,
            maintenance_window_time_range: maintenance_window_time_range,
            alt_maintenance_window_date: alt_maintenance_window_date,
            alt_maintenance_window_time_range: alt_maintenance_window_time_range,
            region: "London"
          )
        ))
      )

      send_email
    end

    it 'should personalise the Notify "maintenance_window_date" field ' do
      expect(notifier.client).to receive(:send_email).with(
        hash_including(personalisation: hash_including(
          maintenance_window_date: maintenance_window_date
        ))
      )

      send_email
    end

    it "should set the reply to adress" do
      expect(notifier.client).to receive(:send_email).with(
        hash_including(
          email_reply_to_id: eq("76d63d5f-e140-6a37-92ae-fc0d0d136f6f")
        )
      )

      send_email
    end
  end
end
