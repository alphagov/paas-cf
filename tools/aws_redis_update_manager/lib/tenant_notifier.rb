require "erb"

require "notifications/client"

class TenantNotifier
  def initialize(notify_api_key)
    @notify_api_key = notify_api_key
  end

  def client
    @client ||= Notifications::Client.new(@notify_api_key)
  end

  AWS_REDIS_UPGRADE_TEMPLATE_ID = "9d0f232b-187c-49b1-8cd1-91e83e347f68".freeze
  PAAS_SUPPORT_REPLY_TO_ID = "76d63d5f-e140-6a37-92ae-fc0d0d136f6f".freeze

  TEMPLATE = <<~MESSAGE.freeze
  Dear GOV.UK PaaS tenant,

  We are contacting you, as a manager of the <%= org_name %> org (<%= region %>), to ask you to review your choice of Redis plans.

  This will help you avoid unnecessary downtime for your users.

  ^ We will be upgrading your Redis instances on <%= maintenance_window_date %>, between <%= maintenance_window_time_range %>

  The following instances will be affected:

  ( Org / Space / Service )

  <% service_instances.each do |si| %>
  - <%= si.org_name %> / <%= si.space_name %> / <%= si.instance_name %>
  <% end %>

  # What this means for you

  If you are using any of our “highly available” Redis plans, your users will only experience a small amount of downtime when the upgrade happens: up to a minute.

  However, if you are using any “tiny” Redis plans that are not “highly available”, your users may experience up to 30 minutes of downtime.

  If you want to minimise this downtime, we recommend that you upgrade these tiny instances to “highly available” plans, ahead of the update on <%= maintenance_window_date %>.

  Note that this will double your monthly charge for each Redis instance: from roughly £25 to £50 per month.

  # How to review your Redis plans

  - Log into your GOV.UK PaaS account and select your region: https://www.cloud.service.gov.uk/sign-in
  - Click on your organisation
  - Click “Explore your costs and usage”
  - Click the dropdown “Services and apps”
  - Look for any “tiny” Redis plans without “ha” in the name, e.g. “redis tiny-4.x”

  # How to upgrade your Redis tiny plans to highly available plans

  - Follow these instructions for every tiny Redis instance you want to upgrade: https://docs.cloud.service.gov.uk/deploying_services/redis/#upgrade-redis-service-plan
  - Upgrade to the “ha” version of your plan, e.g. from “redis tiny-4.x” to “redis tiny-ha-4.x”

  # If the timing of the update doesn’t work for you

  We can offer you the alternative time slot of <%= alt_maintenance_window_date %> between <%= alt_maintenance_window_time_range %>.

  Please reply to this email to request this alternative slot.

  If you have any further questions, please contact GOV.UK PaaS support on gov-uk-paas-support@digital.cabinet-office.gov.uk.

  Please note that if we do not hear from you, we will update your Redis instances on <%= maintenance_window_date %> between <%= maintenance_window_time_range %>, to keep your services secure.

  Kind regards,
  The GOV.UK PaaS Team
  MESSAGE

  def generate_email_contents(
    org_name:,
    service_instances:,
    maintenance_window_date:, maintenance_window_time_range:,
    alt_maintenance_window_date:, alt_maintenance_window_time_range:,
    region:
  )
    ERB.new(TEMPLATE).result_with_hash(
      org_name: org_name,
      service_instances: service_instances,
      maintenance_window_date: maintenance_window_date,
      maintenance_window_time_range: maintenance_window_time_range,
      alt_maintenance_window_date: alt_maintenance_window_date,
      alt_maintenance_window_time_range: alt_maintenance_window_time_range,
      region: region
    )
  end

  def notify_tenant(
    tenant_email_address:,
    org_name:,
    service_instances:,
    maintenance_window_date:, maintenance_window_time_range:,
    alt_maintenance_window_date:, alt_maintenance_window_time_range:,
    region:
  )
    contents = generate_email_contents(
      org_name: org_name,
      service_instances: service_instances,
      maintenance_window_date: maintenance_window_date,
      maintenance_window_time_range: maintenance_window_time_range,
      alt_maintenance_window_date: alt_maintenance_window_date,
      alt_maintenance_window_time_range: alt_maintenance_window_time_range,
      region: region
    )

    client.send_email(
      email_address: tenant_email_address,
      template_id: AWS_REDIS_UPGRADE_TEMPLATE_ID,
      email_reply_to_id: PAAS_SUPPORT_REPLY_TO_ID,
      personalisation: {
        # Template the whole body because we have a list
        contents: contents,
        # Required for templating subject line
        maintenance_window_date: maintenance_window_date,
      }
    )
  end
end
