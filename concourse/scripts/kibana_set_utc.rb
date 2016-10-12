#!/usr/bin/env ruby

require 'net/http'
require 'json'

def config_uri(es_url)
  config_url = "#{es_url}/.kibana/config/4.4.0"
  URI(config_url)
end

def index_settings_uri(es_url)
  index_settings_url = "#{es_url}/.kibana"
  URI(index_settings_url)
end

def update_es_index(uri, document)
  send_request(
    uri: uri,
    http_method: :Put,
    body: document,
    allowed_response_codes: %w(200 201)
  )
end

def send_request(uri:, http_method:, allowed_response_codes:, body: nil)
  raise "Document is not a hash: #{body}" unless body == nil || body.is_a?(Hash)
  response = nil
  Net::HTTP.new(uri.host, uri.port).start do |http|
    method = Net::HTTP.const_get(http_method)
    headers = body ? { 'Content-Type' => 'application/json' } : {}
    req = method.new(uri.path, headers)
    req.body = body.to_json if body
    response = http.request(req)
    unless allowed_response_codes.include?(response.code)
      raise "Unexpected response code: #{response.code}\n#{response.body}"
    end
  end
  response
end

def need_to_create_index(response)
  !response["found"]
end

def need_to_set_timezone(response)
  !response["_source"] || response["_source"]["dateFormat:tz"] != "UTC"
end

def set_utc_config
  es_host = ENV.fetch("ES_HOST")
  es_port = ENV.fetch("ES_PORT")

  es_url = "http://#{es_host}:#{es_port}"

  config_uri = config_uri(es_url)
  response = send_request(uri: config_uri, http_method: :Get, allowed_response_codes: %w(200 404))
  response_json = JSON.parse(response.body)

  if need_to_create_index(response_json)
    index_settings = {
      settings: {
        index: {
          number_of_shards: 1,
          number_of_replicas: 1,
        }
      }
    }
    update_es_index(index_settings_uri(es_url), index_settings)
  end

  if need_to_set_timezone(response_json)
    update_es_index(config_uri(es_url), "dateFormat:tz" => "UTC")
  end
end

set_utc_config
