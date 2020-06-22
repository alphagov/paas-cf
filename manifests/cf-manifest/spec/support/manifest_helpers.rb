require "open3"
require "yaml"
require "singleton"
require "tempfile"

module ManifestHelpers
  class Cache < ::Hash
    include Singleton
  end

  def manifest_without_vars_store
    Cache.instance[:manifest_without_vars_store] ||= \
      render_manifest(
        environment: "default",
      )
  end

  def manifest_with_defaults
    Cache.instance[:manifest_with_defaults] ||= \
      render_manifest_with_vars_store(
        environment: "default",
      )
  end

  def manifest_with_custom_vars_store(vars_store_content)
    render_manifest_with_vars_store(
      environment: "default",
      custom_vars_store_content: vars_store_content,
    )
  end

  def manifest_for_env(deploy_env)
    Cache.instance["manifest_for_env_#{deploy_env}"] ||= render_manifest(
      environment: deploy_env,
      vars_store_file: nil,
      env_specific_bosh_vars_file: "#{deploy_env}.yml",
    )
  end

  def manifest_for_dev
    render_manifest(
      environment: "dev",
    )
  end

  def cf_deployment_manifest
    Cache.instance[:cf_deployment_manifest] ||= YAML.load_file(root.join("manifests/cf-deployment/cf-deployment.yml"))
  end

  def cf_pipeline
    Cache.instance[:cf_pipeline] ||= YAML.load_file(root.join("concourse/pipelines/create-cloudfoundry.yml"))
  end

  def monitor_remote_pipeline
    Cache.instance[:monitor_remote_pipeline] ||= YAML.load_file(root.join("concourse/pipelines/monitor-remote.yml"))
  end

  def property_tree(tree)
    PropertyTree.new(tree)
  end

private

  def root
    Pathname(File.expand_path("../../../..", __dir__))
  end

  def render_vpc_peering_opsfile(dir, environment = "dev")
    FileUtils.mkdir(dir) unless Dir.exist?(dir)
    file = File.open("#{dir}/vpc-peers.yml", "w")
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

  def render_tenant_uaa_clients_opsfile(dir, config_file, environment = "dev")
    FileUtils.mkdir(dir) unless Dir.exist?(dir)

    file = File.open("#{dir}/tenant-uaa-opsfile.yml", "w+")
    output, error, status =
      Open3.capture3(root.join("manifests/cf-manifest/scripts/generate-tenant-uaa-client-ops-file.rb").to_s,
                    root.join(config_file).to_s,
                    environment)

    unless status.success?
      raise "Error generating tenant UAA client ops file, exit: #{status.exitstatus}, output:\n#{output}\n#{error}"
    end

    file.write(output)
    file.flush
    file.rewind
    file
  end

  def render_manifest(
    environment:,
    vars_store_file: nil,
    env_specific_bosh_vars_file: "default.yml"
  )
    workdir = Dir.mktmpdir("paas-cf-test")

    copy_terraform_fixtures("#{workdir}/terraform-outputs")
    copy_fixture_file("bosh-secrets.yml", "#{workdir}/bosh-secrets")
    copy_fixture_file("environment-variables.yml", workdir)
    copy_ipsec_cert_fixtures("#{workdir}/ipsec-CA")
    render_vpc_peering_opsfile("#{workdir}/vpc-peering-opsfile", environment)
    render_tenant_uaa_clients_opsfile("#{workdir}/tenant-uaa-clients-opsfile", "manifests/cf-manifest/spec/fixtures/tenant-uaa-client-fixtures.yml", "dev")

    env = {
      "PAAS_CF_DIR" => root.to_s,
      "WORKDIR" => workdir,
      "ENV_SPECIFIC_BOSH_VARS_FILE" => root.join("manifests/cf-manifest/env-specific/#{env_specific_bosh_vars_file}").to_s,
    }

    if vars_store_file
      env["VARS_STORE"] = vars_store_file
    end

    args = ["#{root}/manifests/cf-manifest/scripts/generate-manifest.sh"]
    output, error, status = Open3.capture3(env, args.join(" "))
    expect(status).to be_success, "generate-manifest.sh exited #{status.exitstatus}, stderr:\n#{error}"

    DeepFreeze.freeze(PropertyTree.load_yaml(output))
  ensure
    FileUtils.rm_rf(workdir)
  end

  def render_manifest_with_vars_store(
    environment:,
    custom_vars_store_content: nil,
    env_specific_bosh_vars_file: "default.yml"
  )
    Tempfile.open(["vars-store", ".yml"]) do |vars_store_tempfile|
      vars_store_tempfile << (custom_vars_store_content || Cache.instance[:vars_store])
      vars_store_tempfile.close

      output = render_manifest(
        environment: environment,
        vars_store_file: vars_store_tempfile.path,
        env_specific_bosh_vars_file: env_specific_bosh_vars_file,
      )

      Cache.instance[:vars_store] = File.read(vars_store_tempfile) if custom_vars_store_content.nil?

      output
    end
  end
end

RSpec.configuration.include ManifestHelpers
