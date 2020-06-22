require "ostruct"

require "aws-sdk-core"
require "aws-sdk-elasticache"

require_relative "cloud_foundry_org_finder"
require_relative "cloud_foundry_service_finder"
require_relative "elasticache_update_finder"
require_relative "paas_accounts_api_client"
require_relative "tenant_notifier"

class AwsRedisUpdateManager
  def initialize(
    paas_accounts_url:,
    paas_accounts_username:,
    paas_accounts_password:
  )
    @elasticache_client = Aws::ElastiCache::Client.new

    @paas_accounts_api_client = PaaSAccountsAPIClient.new(
      url: paas_accounts_url,
      username: paas_accounts_username, password: paas_accounts_password
    )
  end

  def find_service_instances_to_update
    cf_service_finder = CloudFoundryServiceFinder.new("redis")
    service_instances = cf_service_finder.find_service_instances

    elasticache_finder = ElastiCacheUpdateFinder.new(@elasticache_client)
    replication_groups = elasticache_finder
      .find_replication_groups_to_update
      .values
      .flatten

    service_instances_to_update = service_instances
      .select { |s| replication_groups.include? s.replication_group_id }

    service_instances_to_update
  end

  def print_updateable_service_instances
    cf_org_finder = CloudFoundryOrgFinder.new

    find_service_instances_to_update
      .group_by(&:org_guid)
      .each do |org_guid, org_service_instances|
        org = cf_org_finder.find_org(org_guid)

        puts org.org_name

        puts "  Org managers:"
        org.org_manager_guids.each do |org_manager_guid|
          org_manager = @paas_accounts_api_client.find_user(org_manager_guid)
          next if org_manager.nil?

          puts "    #{org_manager.email}"
        end

        puts "  Instances:"
        org_service_instances
          .group_by(&:space_name)
          .each do |space_name, space_service_instances|
            puts "    #{space_name}"
            space_service_instances.each do |service_instance|
              puts "      #{service_instance.instance_name}"
            end
          end
      end
  end

  def preview_updateable_service_instances(
    preview_email:,
    notify_api_key:,
    maintenance_window_date:,
    maintenance_window_time_range:,
    alt_maintenance_window_date:,
    alt_maintenance_window_time_range:,
    region:
  )
    example_service_instance = OpenStruct.new(
      instance_guid: "00000000-1111-2222-3333-444444444444",
      instance_name: "example-service-instance",
      org_guid: "aaaaaaaa-1111-2222-3333-444444444444",
      org_name: "example-org",
      space_guid: "bbbbbbbb-1111-2222-3333-444444444444",
      space_name: "example-space",
    )

    puts "Sending email to #{preview_email}"

    notifier = TenantNotifier.new(notify_api_key)
    notifier.notify_tenant(
      tenant_email_address: preview_email,
      org_name: "example-org",
      service_instances: [example_service_instance],
      maintenance_window_date: maintenance_window_date,
      maintenance_window_time_range: maintenance_window_time_range,
      alt_maintenance_window_date: alt_maintenance_window_date,
      alt_maintenance_window_time_range: alt_maintenance_window_time_range,
      region: region,
    )

    puts "  Sent email to #{preview_email}"
  end

  def notify_org_managers_about_updateable_service_instances(
    notify_api_key:,
    maintenance_window_date:,
    maintenance_window_time_range:,
    alt_maintenance_window_date:,
    alt_maintenance_window_time_range:,
    region:
  )
    cf_org_finder = CloudFoundryOrgFinder.new
    notifier = TenantNotifier.new(notify_api_key)

    find_service_instances_to_update
      .group_by(&:org_guid)
      .each do |org_guid, org_service_instances|
        org = cf_org_finder.find_org(org_guid)

        puts "Notifying managers of #{org.org_name}"

        org.org_manager_guids.each do |org_manager_guid|
          org_manager = @paas_accounts_api_client.find_user(org_manager_guid)
          next if org_manager.nil?

          puts "  Sending email to #{org_manager.email}"

          notifier.notify_tenant(
            tenant_email_address: org_manager.email,
            org_name: org.org_name,
            service_instances: org_service_instances,
            maintenance_window_date: maintenance_window_date,
            maintenance_window_time_range: maintenance_window_time_range,
            alt_maintenance_window_date: alt_maintenance_window_date,
            alt_maintenance_window_time_range: alt_maintenance_window_time_range,
            region: region,
          )

          puts "    Sent email to #{org_manager.email}"
        end
      end
  end
end
