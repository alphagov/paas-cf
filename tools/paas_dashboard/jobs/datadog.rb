require 'dogapi'

STALENESS_THRESHOLD = 900

SCHEDULER.every '10s', allow_overlapping: false do
  get_and_emit_data_for_env(
    service_tag: "service:prod_monitors",
    data_id_prefix: 'prod'
  )
end

SCHEDULER.every '10s', allow_overlapping: false do
  get_and_emit_data_for_env(
    service_tag: "service:staging_monitors",
    data_id_prefix: 'staging'
  )
end

SCHEDULER.every '10s', allow_overlapping: false do
  get_and_emit_data_for_env(
    service_tag: "service:master_monitors",
    data_id_prefix: 'ci'
  )
end

def get_and_emit_data_for_env(service_tag:, data_id_prefix:)
  data_id = "#{data_id_prefix}_counts"

  begin
    results = get_monitor_results(service_tag)
    critical_count, warning_count = get_counts(results)

    send_event(data_id, criticals: critical_count, warnings: warning_count)
  rescue RuntimeError => e
    puts "Error getting data for #{data_id_prefix}: #{e}"
    check_history_for_stale_data(data_id)
  end
end

def get_monitor_results(service_tag)
  dog.get_all_monitors[1].select { |monitor| monitor['tags'].include?(service_tag) }
end

def get_counts(results)
  critical_states = ['Alert']
  warning_states = ['No Data', 'Warn']

  criticals = results.select { |monitor| critical_states.include?(monitor['overall_state']) }.size
  warnings = results.select { |monitor| warning_states.include?(monitor['overall_state']) }.size
  [criticals, warnings]
end

def check_history_for_stale_data(data_id)
  # last event format is "data: #{event_hash.to_json}\n\n"
  last_event = JSON.parse(Sinatra::Application.settings.history[data_id][6..-2])
  if ! last_event_error?(last_event) && last_event_stale?(last_event)
    send_event(data_id, error: 'Stale data')
  end
end

def last_event_error?(last_event)
  last_event['error']
end

def last_event_stale?(last_event)
  last_event['updatedAt'] + STALENESS_THRESHOLD < Time.now.to_i
end

def dog
  @dog ||= Dogapi::Client.new(ENV['DD_API_KEY'], ENV['DD_APP_KEY'], nil, nil, false)
end
