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
    attr_accessor :cf_deployment_manifest
    attr_accessor :cf_pipeline
    attr_accessor :vars_store
  end

  def workdir
    Cache.instance.workdir ||= $workdir
  end

  def manifest_without_vars_store
    Cache.instance.manifest_without_vars_store ||= \
      render_manifest(
        environment: "default",
        disable_user_creation: "true",
      )
  end

  def manifest_with_defaults
    Cache.instance.manifest_with_defaults ||= \
      render_manifest_with_vars_store(
        environment: "default",
        disable_user_creation: "true",
      )
  end

  def manifest_with_custom_vars_store(vars_store_content)
    render_manifest_with_vars_store(
      environment: "default",
      disable_user_creation: "true",
      custom_vars_store_content: vars_store_content,
    )
  end

  def manifest_with_enable_user_creation
    render_manifest_with_vars_store(
      environment: "default",
      disable_user_creation: "false",
    )
  end

  def manifest_for_prod
    render_manifest(
      environment: "prod",
      disable_user_creation: "true",
      vars_store_file: nil,
      env_specific_bosh_vars_file: "prod.yml",
    )
  end

  def manifest_for_dev
    render_manifest(
      environment: "dev",
      disable_user_creation: "true",
    )
  end

  def cf_deployment_manifest
    Cache.instance.cf_deployment_manifest ||= YAML.load_file(root.join('manifests/cf-deployment/cf-deployment.yml'))
  end

  def cf_pipeline
    Cache.instance.cf_pipeline ||= YAML.load_file(root.join('concourse/pipelines/create-cloudfoundry.yml'))
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
    disable_user_creation:,
    vars_store_file: nil,
    env_specific_bosh_vars_file: "default.yml"
  )
    copy_terraform_fixtures("#{workdir}/terraform-outputs")
    copy_fixture_file('logit-secrets.yml', "#{workdir}/logit-secrets")
    copy_fixture_file('bosh-secrets.yml', "#{workdir}/bosh-secrets")
    generate_cf_secrets_fixture("#{workdir}/cf-secrets")
    copy_fixture_file('environment-variables.yml', workdir)
    copy_ipsec_cert_fixtures("#{workdir}/ipsec-CA")
    render_vpc_peering_opsfile(environment)

    env = {
      'PAAS_CF_DIR' => root.to_s,
      'WORKDIR' => workdir,
      'ENV_SPECIFIC_BOSH_VARS_FILE' => root.join("manifests/cf-manifest/env-specific/#{env_specific_bosh_vars_file}").to_s,
      'DISABLE_USER_CREATION' => disable_user_creation
    }

    if vars_store_file
      env["VARS_STORE"] = vars_store_file
    end

    args = ["#{root}/manifests/cf-manifest/scripts/generate-manifest.sh"]
    output, error, status = Open3.capture3(env, args.join(' '))
    expect(status).to be_success, "generate-manifest.sh exited #{status.exitstatus}, stderr:\n#{error}"

    DeepFreeze.freeze(PropertyTree.load_yaml(output))
  end

  def render_manifest_with_vars_store(
    environment:,
    disable_user_creation:,
    custom_vars_store_content: nil,
    env_specific_bosh_vars_file: "default.yml"
  )
    Tempfile.open(['vars-store', '.yml']) { |vars_store_tempfile|
      vars_store_tempfile << (custom_vars_store_content || Cache.instance.vars_store)
      vars_store_tempfile.close

      output = render_manifest(
        environment: environment,
        disable_user_creation: disable_user_creation,
        vars_store_file: vars_store_tempfile.path,
        env_specific_bosh_vars_file: env_specific_bosh_vars_file,
      )

      Cache.instance.vars_store = File.read(vars_store_tempfile) if custom_vars_store_content.nil?

      output
    }
  end
end

RSpec.configuration.include ManifestHelpers
