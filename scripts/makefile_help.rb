#!/usr/bin/env ruby
##
# Generate formatted help text for the current git repo's Makefile
#
# Makefile sections are defined witha section marker:
#   ##SECTION Section name
#
#   section_name: "Section name"
#
# Make targets are documented with a comment on the same line as the section:
#   make_target_name: dependencies ## help text
#
#   target: "make_target_name"
#   help_text: "help text"
#
# All targets following a section marker are classed as part of that section.
# Any target not in a section (ie. defined before the first section marker)
# are part of a default "Ungrouped" section.
#
# Output format:
#
#   Ungrouped
#     some_ungrouped_target        Help text for target
#     some_other_ungrouped_target  Help text for target
#   Some section
#     some_grouped_target          Help text for target
#     some_other_grouped_target    Help text for target
#   ...
#
# Output has nice pretty colors.
require "open3"

##
# Get the root of the current git repository
#
# @raise [RuntimeError] if not a git repo
# @return [String] Path to root of git repo
def get_git_root
  gr, err, status = Open3.capture3("git rev-parse --show-toplevel")
  unless status.success?
    raise err
  end

  gr.chop
end

GIT_ROOT = get_git_root

MAKEFILE_PATH = "#{GIT_ROOT}/Makefile".freeze

section = "00000000Ungrouped" # default section (targets before the first ##SECTION) (0000s are to ensure it's sorted first later)

targets = { section => {} } # hash to store section:target:help_text
longest = 0 # length of longest target name (for formatting)

##
# Read the Makefile line by line and extract targets
File.open(MAKEFILE_PATH) do |f|
  while (line = f.gets)
    if line.match(/^##SECTION/) # This line is a section marker
      section = if /##SECTION\s(.*)$/ =~line
                  Regexp.last_match(1).strip # extract the section name
                end
      targets[section] = {} # add empty section hash to the entries hash
    elsif /([a-zA-Z_-]+):.*?##(.*)$/=~line # This line is a make target (entry: ##help text)
      target = Regexp.last_match(1) # target name
      targets[section][target] = Regexp.last_match(2).strip.capitalize # target help text
      if target.length > longest # this target's name is longer than the current longest
        longest = target.length # set the longest length to the length of this target
      end
    end
  end
end
spacing = longest + 1 # Ensure that we add a space between the target name and the help text
targets.sort.to_h.each do |section_name, section_targets|
  if section_name == "00000000Ungrouped"
    section_name = "Ungrouped" # Make the default group name nicer
  end
  if section_targets.empty?
    next # if there are no targets in the section, don't output it
  end

  puts "\e[1;33m#{section_name}\e[0m" # print the section name in bold yellow
  section_targets.sort.to_h.each do |entry, helptext|
    puts "  \e[36m#{entry}\e[0m#{' ' * (spacing - entry.length)}#{helptext}" # print the targets in blue
  end
end
