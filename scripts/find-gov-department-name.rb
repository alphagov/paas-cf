#!/usr/bin/env ruby

require 'register_client_manager'
require 'fuzzy_match'
require 'tty-prompt'

OPT_NONE_OF_THE_ABOVE = "None of the above"

client_mgr = RegistersClient::RegisterClientManager.new({
  page_size: 5000
})

initial_input = ARGV.join(' ')

abort "Usage: #{$0} gov-dept-search-substring" if ARGV.empty?

prompt = TTY::Prompt.new(output: STDERR)

def sorted_matches(matchset, search_term)
  FuzzyMatch
    .new(matchset)
    .find_all_with_score(search_term)
    .map { |dept, _pair_dist, _lev_dist| dept }
end

def opts_or_none(opts)
  [OPT_NONE_OF_THE_ABOVE].concat(opts)
end

client = client_mgr.get_register('government-organisation', 'beta')
dept_names = client.get_records.map { |r| r.item.value['name'] }

selected_name = nil
input = initial_input
loop do
  break unless selected_name.nil?

  choice = prompt.enum_select(
    'Did you mean?',
    opts_or_none(sorted_matches(dept_names, input))
  )
  if choice != OPT_NONE_OF_THE_ABOVE
    selected_name = choice
    break
  end

  choice = prompt.ask("Couldn't find a department with a name close enough to '#{input}'. Try another name (or leave empty to quit)")

  if choice.nil?
    prompt.say('Stopping')
    exit(1)
  end

  input = choice
end

puts selected_name
