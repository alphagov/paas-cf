class UAAResource
  attr_reader :guid

  def get_resource(url, uaa_client)
    resp = uaa_client[url].get

    raise "unexpected response fetching '#{url}'" unless resp.code == 200

    parsed_resp = JSON.parse(resp)
    raise "unexpected number of results fetching '#{url}': '#{parsed_resp['totalResults']}'" unless parsed_resp['totalResults'] == 1

    @guid = parsed_resp['resources'][0]['id']
    parsed_resp['resources'][0]
  end
end
