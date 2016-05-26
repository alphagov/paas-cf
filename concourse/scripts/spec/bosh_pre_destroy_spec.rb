require 'yaml'
require 'mimic'

RSpec.describe "bosh_pre_destroy.rb", :type => :aruba do
  before(:each) do
    bosh_host = "127.0.0.1"
    bosh_port = 25555

    @fake_bosh = Mimic.mimic(:hostname => bosh_host, :port => bosh_port) do
      get("/info").returning('{}', 200)
    end

    bosh_config = {'target' => "http://#{bosh_host}:#{bosh_port}"}
    bosh_config_file = Tempfile.new('bosh_config')
    bosh_config_file.write(bosh_config.to_yaml)
    bosh_config_file.close
    set_environment_variable('BOSH_CONFIG', bosh_config_file.path)
  end

  after(:each) do
    Mimic.cleanup!
  end

  context("no deployments") do
    before(:each) do
      @fake_bosh.get("/deployments").returning('{}', 200)
    end

    it "it should return a zero exit code and no output" do
      run("./bosh_pre_destroy.rb")
      expect(last_command_started).to have_exit_status(0)
      expect(last_command_started.stdout).to be_empty
      expect(last_command_started.stderr).to be_empty
    end
  end

  context("two deployments") do
    before(:each) do
      @fake_bosh.get("/deployments").returning('[{"name": "one"}, {"name": "two"}]', 200)
    end

    it "it should return a non-zero exit code and list of deployments" do
      run("./bosh_pre_destroy.rb")
      expect(last_command_started).to have_exit_status(1)
      expect(last_command_started.stdout).to be_empty
      expect(last_command_started.stderr).to eq <<-EOF
The following deployments must be deleted before destroying BOSH:
- one
- two
      EOF
    end
  end
end
