require "English"
require "json"

class CloudFoundryOrgFinder
  def initialize
    @orgs = {}
  end

  def find_org(org_guid)
    @orgs[org_guid] if @orgs[org_guid]

    org = get_org(org_guid)

    roles_url = "/v3/roles?organization_guids=#{org_guid}"
    roles = paginate_v3(roles_url)

    org_managers = roles.select { |r| r["type"] == "organization_manager" }

    org_manager_guids = org_managers.map do |o|
      o.dig("relationships", "user", "data", "guid")
    end

    @orgs[org_guid] ||= OpenStruct.new(
      org_guid: org_guid,
      org_name: org["name"],
      org_manager_guids: org_manager_guids
    )
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

  def get_org(org_guid)
    path = "/v3/organizations/#{org_guid}"
    body = `cf curl '#{path}'`
    raise body unless $CHILD_STATUS.success?
    JSON.parse(body)
  end
end
