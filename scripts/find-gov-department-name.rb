require 'register_client_manager'
require 'levenshtein'
require 'tty-prompt'

OPT_NONE_OF_THE_ABOVE = "None of the above"

client_mgr = RegistersClient::RegisterClientManager.new({
	page_size: 5000
})

initial_input = ARGV[0]
prompt = TTY::Prompt.new({
	"output":  STDERR
})

def compute_distances(strings, input)
	map = {}
	strings.each{|s|
		map[s] = Levenshtein.normalized_distance(input, s)
	}

	return map
end

def names_containing(strings, input)
	strings.select{ |s| s.include? input }
end

def opts_or_none(opts)
	opts.push(OPT_NONE_OF_THE_ABOVE)
end

dept_names = []
client = client_mgr.get_register('government-organisation', 'beta')
dept_names = client.get_records.map{ |r|
	r.item.value["name"]
}
selected_name = nil
input = initial_input
while selected_name == nil do
	distances = compute_distances(dept_names, input)

	almost_zero_distances = distances.select{ |k, v| v <= 0.3 }
	if !almost_zero_distances.empty?
		choice = prompt.enum_select('Did you mean?', opts_or_none(almost_zero_distances.keys))
		if choice != OPT_NONE_OF_THE_ABOVE
			selected_name = choice
			break
		end
	else
		seventy_five_pc = distances.select{ |k, v| v <= 0.5 }
  	if !seventy_five_pc.empty?
      choice = prompt.enum_select('Did you mean?', opts_or_none(seventy_five_pc.keys))

			if choice != OPT_NONE_OF_THE_ABOVE
				selected_name = choice
				break
			end
		else
      just_including = names_containing(dept_names, input)
     	if !just_including.empty?
         choice = prompt.enum_select('Did you mean?', opts_or_none(just_including))

         if choice != OPT_NONE_OF_THE_ABOVE
          selected_name = choice
          break
         end
      end
    end
	end

  choice = prompt.ask("Couldn't find a department wit a name close enough to '#{input}'. Try another name (or leave empty to quit)")
  if choice == nil
    prompt.say("Stopping")
    exit(1)
  end

  input = choice
end

puts selected_name
