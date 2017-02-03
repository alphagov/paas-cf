#!/usr/bin/env ruby

require 'json'
require 'dogapi'

tfstate = JSON.load($stdin)

def to_boolean(str)
  str == 'true'
end

def find_monitors(tfstate)
  monitor_ids = Hash.new
  tfstate['modules'][0]['resources'].each do |_, name|
    attributes = Hash.new
    if name["type"] == "datadog_monitor"
      name["primary"]["attributes"].each do |attribute, value|
        # Optimise for require_full_window attribute only as others have sane defaults
        if attribute == "require_full_window" && value == "false"
          attributes[attribute] = to_boolean(value)
        end
      end
      if attributes != {}
        monitor_ids[name["primary"]["id"]] = attributes
      end
    end
  end
  monitor_ids
end

def update_monitors(monitor_ids, api_client)
  monitor_ids.each do |id, tfstate_options|
    resp, monitor = api_client.get_monitor(id)
    if resp != "200"
      abort("Get monitor failed. Got response: #{resp}. Error message: #{monitor}")
    end
    options = monitor["options"]
    options.merge!(tfstate_options)
    query = monitor["query"]
    resp, body = api_client.update_monitor(id, query, options: options)
    if resp != "200"
      abort("Update failed. Got response: #{resp}. Error message: #{body}")
    end
    puts "Updated monitor #{id} with attributes #{options}"
  end
  nil
end

api_key = ENV['TF_VAR_datadog_api_key']
app_key = ENV['TF_VAR_datadog_app_key']
api_host = ARGV[0]
dog = Dogapi::Client.new(api_key, app_key, nil, nil, nil, nil, api_host)
monitor_ids = find_monitors(tfstate)
update_monitors(monitor_ids, dog)
