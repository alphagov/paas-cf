class UAAResource
  attr_reader :guid

  def get(url, uaa_client)
    resp = uaa_client[url].get
    unless resp.code == 200
      raise "unexpected response fetching '#{url}'"
    end

    JSON.parse(resp)
  end

  def get_resource(url, uaa_client)
    response = get(url, uaa_client)
    unless response["totalResults"] == 1
      raise "unexpected number of results fetching '#{url}': '#{response['totalResults']}'"
    end

    @guid = response["resources"][0]["id"]
    response["resources"][0]
  end
end
