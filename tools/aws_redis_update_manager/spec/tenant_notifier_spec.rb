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
        org_name:,
        space_name: "a-space",
        instance_name: "an-instance",
      ),
      OpenStruct.new(
        org_name:,
        space_name: "another-space",
        instance_name: "another-instance",
      ),
    ]
  end

  let(:maintenance_window_date) { "2038/01/19" }
  let(:maintenance_window_time_range) { "2000-2100" }

  context "when generating an email" do
    let(:contents) do
      TenantNotifier.new(notify_api_key).generate_email_contents(
        org_name:,
        service_instances:,
        maintenance_window_date:,
        maintenance_window_time_range:,
        region: "London",
      )
    end

    it "lists the service instances to be updated" do
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

    it "includes the maintenance window" do
      expect(contents).to match(
        "on #{maintenance_window_date}, between #{maintenance_window_time_range}",
      )
    end

    it "includes the region" do
      expect(contents).to match(
        "(London)",
      )
    end
  end

  context "when notifying a tenant" do
    let(:notifier) { TenantNotifier.new(notify_api_key) }
    let(:send_email) do
      notifier.notify_tenant(
        tenant_email_address:,
        org_name:,
        service_instances:,
        maintenance_window_date:,
        maintenance_window_time_range:,
        region: "London",
      )
    end

    before do
      notifier.instance_variable_set(:@client, double)
      allow(notifier.client).to receive(:send_email)
    end

    it 'personalises the Notify "contents" field' do
      expect(notifier.client).to receive(:send_email).with(
        hash_including(personalisation: hash_including(
          contents: TenantNotifier.new(notify_api_key).generate_email_contents(
            org_name:,
            service_instances:,
            maintenance_window_date:,
            maintenance_window_time_range:,
            region: "London",
          ),
        )),
      )

      send_email
    end

    it 'personalises the Notify "maintenance_window_date" field' do
      expect(notifier.client).to receive(:send_email).with(
        hash_including(personalisation: hash_including(
          maintenance_window_date:,
        )),
      )

      send_email
    end

    it "sets the reply to adress" do
      expect(notifier.client).to receive(:send_email).with(
        hash_including(
          email_reply_to_id: eq("76d63d5f-e140-6a37-92ae-fc0d0d136f6f"),
        ),
      )

      send_email
    end
  end
end
