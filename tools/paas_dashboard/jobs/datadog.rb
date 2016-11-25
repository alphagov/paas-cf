require 'dogapi'

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
  results = get_monitor_results(service_tag)
  critical_count, warning_count = get_counts(results)
  send_event("#{data_id_prefix}_counts", criticals: critical_count, warnings: warning_count)
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

def dog
  @dog ||= Dogapi::Client.new(ENV['DD_API_KEY'], ENV['DD_APP_KEY'])
end
