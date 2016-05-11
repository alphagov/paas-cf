require 'yaml'

RSpec.describe "extract quota settings", :type => :aruba do

  context("the directory argument is missing") do
    it "should fail with code 100" do
      run("./extract_quota_settings.rb")
      expect(last_command_started).to have_exit_status(100)
    end
  end

  context("the directory argument is not a directory") do
    it "should fail with code 100" do
      run("./extract_quota_settings.rb abcd")
      expect(last_command_started).to have_exit_status(100)
    end
  end

  context("the CF_MANIFEST variable is missing") do
    it "should fail with code 100" do
      run("./extract_quota_settings.rb .")
      expect(last_command_started).to have_exit_status(100)
    end
  end

  context("given a yaml with 2 quota definitions") do

  quotas_yaml = <<EOF
properties:
  cc:
    quota_definitions:
      default:
        memory_limit: 2048
        total_services: 10
        non_basic_services_allowed: false
        total_routes: 1000
      big_mem:
        memory_limit: 60000
        total_services: 10
        non_basic_services_allowed: false
        total_routes: 1000
    default_quota_definition: default
EOF

    it "should create 2 files with environment variables" do
      write_file 'manifest.yml', quotas_yaml
      set_environment_variable "CF_MANIFEST", "manifest.yml"
      run("./extract_quota_settings.rb .")
      expect("default_quota.sh").to be_an_existing_file
      default_quota = <<EOF
export QUOTA_name='default'
export QUOTA_memory_limit='2048'
export QUOTA_total_services='10'
export QUOTA_non_basic_services_allowed='false'
export QUOTA_total_routes='1000'
EOF
      expect("default_quota.sh").to have_file_content default_quota

      expect("big_mem_quota.sh").to be_an_existing_file
      big_mem_quota = <<EOF
export QUOTA_name='big_mem'
export QUOTA_memory_limit='60000'
export QUOTA_total_services='10'
export QUOTA_non_basic_services_allowed='false'
export QUOTA_total_routes='1000'
EOF
      expect("big_mem_quota.sh").to have_file_content big_mem_quota
    end

  end

end
