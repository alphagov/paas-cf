require "pathname"
require "tempfile"

# Find the directory of the current git repo
def find_git_repository_path()
  path = `git rev-parse --show-toplevel`.strip
  if not File.exists?(path)
    raise "Cannot find a git repository parent of #{File.dirname(__FILE__)}"
  end
  return path
end

def repostory_name()
  File.basename(find_git_repository_path())
end

# Link the current git repo to the aruba working dir. \
# This is might be useful to simulate a concourse scenario
def init_concourse_working_directory()
  @repo_root = find_git_repository_path
  @repo_name = File.basename(@repo_root)

  # Link the repository directory, as it is done in concourse
  FileUtils.ln_s(@repo_root, File.join(@workdir,  @repo_name))
end


# Helper to run a bash script in verbose mode and capturing
# all output together
#
# Good for scripts and initialise stuff
#
def bash_block(script, options = {})

  bash_options = ""
  if not options[:continue_on_error]
    bash_options += "-e "
  end
  if not options[:continue_on_unbound_var]
    bash_options += "-u "
  end
  if not options[:continue_on_pipefail]
    bash_options += "-o pipefail "
  end
  if not options[:quiet]
    bash_options += "-x "
  end

  Tempfile.open('tmp_script') do | f |
    f.puts("exec 2>&1 # Redirect stderr to stdout")
    f.puts("#{script}")
    f.close
    run_simple("bash #{bash_options} #{f.path}")
  end

  if options[:debug]
    puts last_command_started.output
  end

end

