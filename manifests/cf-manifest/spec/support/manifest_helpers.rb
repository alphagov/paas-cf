require 'open3'
require 'yaml'
require 'singleton'
require 'tempfile'

module ManifestHelpers
  class Cache
    include Singleton
    attr_accessor :workdir
    attr_accessor :manifest_with_defaults
    attr_accessor :manifest_without_vars_store
    attr_accessor :manifest_with_datadog_enabled
    attr_accessor :cf_deployment_manifest
    attr_accessor :cloud_config_with_defaults
    attr_accessor :terraform_fixture
    attr_accessor :cf_secrets_file
    attr_accessor :vars_store
  end

  def workdir
    Cache.instance.workdir ||= $workdir
  end

  def manifest_without_vars_store
    Cache.instance.manifest_without_vars_store ||= \
      render_manifest(
        environment: "default",
        enable_datadog: "false",
        disable_user_creation: "true",
        extra_args: [],
      )
  end

  def manifest_with_defaults
    Cache.instance.manifest_with_defaults ||= \
      render_manifest_with_vars_store(
        environment: "default",
        enable_datadog: "false",
        disable_user_creation: "true",
      )
  end

  def manifest_with_custom_vars_store(vars_store_content)
    render_manifest_with_vars_store(
      environment: "default",
      enable_datadog: "false",
      disable_user_creation: "true",
      custom_vars_store_content: vars_store_content,
    )
  end

  def manifest_with_datadog_enabled
    Cache.instance.manifest_with_datadog_enabled ||= \
      render_manifest_with_vars_store(
        environment: "default",
        enable_datadog: "true",
        disable_user_creation: "true",
      )
  end

  def manifest_with_enable_user_creation
    render_manifest_with_vars_store(
      environment: "default",
      enable_datadog: "false",
      disable_user_creation: "false",
    )
  end

  def manifest_for_prod
    render_manifest(
      environment: "prod",
      enable_datadog: "false",
      disable_user_creation: "true",
      env_specific_manifest: "prod",
      extra_args: [],
    )
  end

  def manifest_for_dev
    render_manifest(
      environment: "dev",
      enable_datadog: "false",
      disable_user_creation: "true",
      extra_args: [],
    )
  end

  def cf_deployment_manifest
    Cache.instance.cf_deployment_manifest ||= YAML.load_file(root.join('manifests/cf-deployment/cf-deployment.yml'))
  end

  def cloud_config_with_defaults
    Cache.instance.cloud_config_with_defaults ||= render_cloud_config
  end

  def terraform_fixture(key)
    Cache.instance.terraform_fixture ||= load_terraform_fixture
    Cache.instance.terraform_fixture.fetch('terraform_outputs_' + key.to_s)
  end

  def cf_secrets_file
    Cache.instance.cf_secrets_file ||= generate_cf_secrets
    Cache.instance.cf_secrets_file.path
  end

  def property_tree(tree)
    PropertyTree.new(tree)
  end

private

  def root
    Pathname(File.expand_path("../../../..", __dir__))
  end

  def render_vpc_peering_opsfile(environment = "dev")
    dir = workdir + '/vpc-peering-opsfile'
    FileUtils.mkdir(dir) unless Dir.exist?(dir)
    file = File::open("#{dir}/vpc-peers.yml", 'w')
    output, error, status =
      Open3.capture3(root.join("terraform/scripts/generate_vpc_peering_opsfile.rb").to_s,
                     root.join("terraform/#{environment}.vpc_peering.json").to_s)
    unless status.success?
      raise "Error generating vpc peering opsfile, exit: #{status.exitstatus}, output:\n#{output}\n#{error}"
    end
    file.write(output)
    file.flush
    file.rewind
    file
  end

  def render_manifest(
    environment:,
    enable_datadog:,
    disable_user_creation:,
    extra_args:,
    env_specific_manifest: "default"
  )
    copy_terraform_fixtures
    copy_logit_fixtures
    generate_cf_secrets
    copy_environment_variables
    copy_certs
    render_vpc_peering_opsfile(environment)

    env = {
      'PAAS_CF_DIR' => root.to_s,
      'WORKDIR' => workdir,
      'CF_ENV_SPECIFIC_MANIFEST' => root.join("manifests/cf-manifest/env-specific/cf-#{env_specific_manifest}.yml").to_s,
      'ENABLE_DATADOG' => enable_datadog,
      'DISABLE_USER_CREATION' => disable_user_creation
    }
    args = ["#{root}/manifests/cf-manifest/scripts/generate-manifest.sh"] + extra_args
    output, error, status = Open3.capture3(env, args.join(' '))
    expect(status).to be_success, "generate-manifest.sh exited #{status.exitstatus}, stderr:\n#{error}"

    DeepFreeze.freeze(PropertyTree.load_yaml(output))
  end

  def render_manifest_with_vars_store(
    environment:,
    enable_datadog:,
    disable_user_creation:,
    custom_vars_store_content: nil,
    env_specific_manifest: "default"
  )
    Tempfile.open(['vars-store', '.yml']) { |vars_store_tempfile|
      vars_store_tempfile << (custom_vars_store_content || Cache.instance.vars_store)
      vars_store_tempfile.close

      args = %W{
        --var-errs
        --vars-store=#{vars_store_tempfile.path}
      }
      output = render_manifest(
        environment: environment,
        enable_datadog: enable_datadog,
        disable_user_creation: disable_user_creation,
        extra_args: args,
        env_specific_manifest: env_specific_manifest,
      )

      Cache.instance.vars_store = File.read(vars_store_tempfile) if custom_vars_store_content.nil?

      output
    }
  end

  def render_cloud_config(environment = "default")
    copy_terraform_fixtures
    generate_cf_secrets
    copy_environment_variables

    env = {
      'PAAS_CF_DIR' => root.to_s,
      'WORKDIR' => workdir,
      'CF_ENV_SPECIFIC_MANIFEST' => root.join("manifests/cf-manifest/env-specific/cf-#{environment}.yml").to_s,
    }
    output, error, status = Open3.capture3(env, root.join('manifests/cf-manifest/scripts/generate-cloud-config.sh').to_s)
    expect(status).to be_success, "generate-cloud-config.sh exited #{status.exitstatus}, stderr:\n#{error}"

    DeepFreeze.freeze(PropertyTree.load_yaml(output))
  end

  def copy_terraform_fixtures
    dir = workdir + '/terraform-outputs'
    FileUtils.mkdir(dir) unless Dir.exist?(dir)

    %w(vpc bosh concourse cf).each { |file|
      FileUtils.cp(
        root.join("manifests/shared/spec/fixtures/terraform/#{file}.yml"),
        "#{dir}/#{file}.yml",
      )
    }
  end

  def copy_logit_fixtures
    dir = workdir + '/logit-secrets'
    FileUtils.mkdir(dir) unless Dir.exist?(dir)

    FileUtils.cp(
      root.join("manifests/shared/spec/fixtures/logit-secrets.yml"),
      "#{dir}/logit-secrets.yml",
    )
  end

  def copy_environment_variables
    FileUtils.cp(
      root.join("manifests/shared/spec/fixtures/environment-variables.yml"),
      "#{workdir}/environment-variables.yml",
    )
  end

  def copy_certs
    dir = workdir + '/ipsec-CA'
    FileUtils.mkdir(dir) unless Dir.exist?(dir)
    FileUtils.cp(
      root.join("manifests/shared/spec/fixtures/ipsec-CA.crt"),
      "#{dir}/ipsec-CA.crt",
    )
    FileUtils.cp(
      root.join("manifests/shared/spec/fixtures/ipsec-CA.key"),
      "#{dir}/ipsec-CA.key",
    )
  end

  def load_terraform_fixture
    data = YAML.load_file(root.join("manifests/shared/spec/fixtures/terraform/cf.yml"))
    DeepFreeze.freeze(data)
  end

  def generate_cf_secrets
    dir = workdir + '/cf-secrets'
    FileUtils.mkdir(dir) unless Dir.exist?(dir)
    file = File::open("#{dir}/cf-secrets.yml", 'w')
    output, error, status = Open3.capture3(File.expand_path("../../../scripts/generate-cf-secrets.rb", __FILE__))
    unless status.success?
      raise "Error generating cf-secrets, exit: #{status.exitstatus}, output:\n#{output}\n#{error}"
    end
    file.write(output)
    file.flush
    file.rewind
    file
  end
end

RSpec.configuration.include ManifestHelpers
