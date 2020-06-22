# rubocop:disable Style/MultilineBlockChain
require "English"
require "json"
require "ostruct"

require_relative "fnv"

class CloudFoundryServiceFinder
  def initialize(service_offering_name)
    @service_offering_name = service_offering_name
  end

  def find_service_instances
    service_instances.map do |service_instance_guid, service_instance|
      space_guid = service_instance.dig("entity", "space_guid")
      space = spaces[space_guid]

      org_guid = space.dig("relationships", "organization", "data", "guid")
      org = orgs[org_guid]

      service_instance = OpenStruct.new(
        instance_guid: service_instance_guid,
        instance_name: service_instance.dig("entity", "name"),
        org_guid: org_guid,
        org_name: org.fetch("name"),
        space_guid: space_guid,
        space_name: space.fetch("name"),
      )

      if @service_offering_name == "redis"
        elasticache_id = fnv(service_instance_guid)
        service_instance.replication_group_id = "cf-#{elasticache_id}"
      end

      service_instance
    end
  end

private

  def cf_curl_path(url)
    url.sub(%r{^.*/(v[23])/}, '/\1/')
  end

  def paginate_v3(url)
    path = cf_curl_path(url)
    resources = []

    loop do
      body = `cf curl '#{path}'`
      raise body unless $CHILD_STATUS.success?

      resp = JSON.parse(body)
      resources += resp.fetch("resources")

      break if resp.dig("pagination", "next").nil?

      path = cf_curl_path(resp.dig("pagination", "next", "href"))
    end

    resources.uniq { |r| r.fetch("guid") }
  end

  def paginate_v2(url)
    path = cf_curl_path(url)
    resources = []

    loop do
      body = `cf curl '#{path}'`
      raise body unless $CHILD_STATUS.success?

      resp = JSON.parse(body)
      resources += resp.fetch("resources")

      break if resp.dig("next_url").nil?

      path = cf_curl_path(resp.dig("next_url"))
    end

    resources.uniq { |r| r.dig("metadata", "guid") }
  end

  def service_offering
    @service_offering ||= paginate_v3("v3/service_offerings").find do |o|
      o.fetch("name") == @service_offering_name
    end
  end

  def service_plans
    @service_plans ||= paginate_v3(
      service_offering.dig("links", "service_plans", "href"),
    )
  end

  def service_instances
    service_plan_guids = service_plans.map { |p| p.fetch("guid") }

    # our capi does not support plan_guid in service_instances
    @service_instances ||= paginate_v2("/v2/service_instances")
      .select { |i|
        plan_guid = i.dig("entity", "service_plan_guid")
        service_plan_guids.include? plan_guid
      }
      .group_by { |i| i.dig("metadata", "guid") }
      .transform_values(&:first)
  end

  def orgs
    @orgs ||= paginate_v3("/v3/organizations")
      .group_by { |o| o.fetch("guid") }
      .transform_values(&:first)
  end

  def spaces
    @spaces ||= paginate_v3("/v3/spaces")
      .group_by { |o| o.fetch("guid") }
      .transform_values(&:first)
  end
end
# rubocop:enable Style/MultilineBlockChain
