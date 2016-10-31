require 'dogapi'

SCHEDULER.every '10s', allow_overlapping: false do
  get_and_emit_counts_for_env(
    env_tag: "environment:prod",
    data_id: 'prod'
  )
end

SCHEDULER.every '10s', allow_overlapping: false do
  get_and_emit_counts_for_env(
    env_tag: "environment:staging",
    data_id: 'staging'
  )
end

SCHEDULER.every '10s', allow_overlapping: false do
  get_and_emit_counts_for_env(
    env_tag: "environment:master",
    data_id: 'ci'
  )
end

def get_and_emit_counts_for_env(env_tag:, data_id:)
  results = get_monitors(env_tag)
  critical_count, warning_count = get_counts(results)
  send_event(data_id, criticals: critical_count, warnings: warning_count)
end

def get_monitors(env)
  dog.get_all_monitors(tags: [env])[1]
end

def get_counts(results)
  criticals = results.select { |monitor| ['Alert'].include?(monitor['overall_state']) }.size
  warnings = results.select { |monitor| ['No Data', 'Warning'].include?(monitor['overall_state']) }.size
  [criticals, warnings]
end

def dog
  @dog ||= Dogapi::Client.new(ENV['DD_API_KEY'], ENV['DD_APP_KEY'])
end
