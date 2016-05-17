require "aruba/rspec"

RSpec.configure do |rspec_config|
  rspec_config.before(:all) do
    # We run scripts with git commands, and as we don't want to mess around
    # with our own repository, we setup the workdir in a different location.
    @workdir = Dir.mktmpdir("paas-cf-tmpdir-")
    # Aruba requires the workdir path to be a relative directory
    relative_workdir = Pathname.new(@workdir).relative_path_from(Pathname.pwd)

    Aruba.configure do |aruba_config|
      aruba_config.working_directory = relative_workdir
      aruba_config.home_directory = @workdir
      aruba_config.command_search_paths = [
        File.join(File.join(__FILE__, "..", "..")),
      ]
    end
  end
  rspec_config.after(:all) do
    # Ensure we clean up after
    def rmdir(dir)
      FileUtils.rmdir(dir) if File.exist? dir
    end
    rmdir @workdir
  end
  rspec_config.after(:each) do |example|
    # Small hack to get the output of the last command in the rspec
    # failure report. If anybody knows a better solution, please propose it.
    if example.exception != nil and defined?(last_command_started) and last_command_started.exit_status != 0
      raise Exception.new("Last command output: " + last_command_started.output)
    end
  end
end

