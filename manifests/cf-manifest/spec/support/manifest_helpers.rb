require 'open3'
require 'yaml'
require 'singleton'
require 'tempfile'

module ManifestHelpers
  class PropertyTree
    def initialize(tree)
      @tree = tree
    end

    def self.load_yaml(yaml_string)
      PropertyTree.new(YAML.safe_load(yaml_string))
    end

    def recursive_get(tree, key_array)
      return tree if key_array.empty?
      current_key, *next_keys = key_array

      next_level = case tree
                   when Hash
                     tree[current_key]
                   when Array
                     if current_key =~ /\A[-+]?\d+\z/ # If the key is an int, access by index
                       tree[current_key.to_i]
                     else # if not, search for a element with `name: current_key`
                       tree.select { |x| x.is_a?(Hash) && x['name'] == current_key }.first
                     end
                   end
      if not next_level.nil?
        recursive_get(next_level, next_keys)
      end
    end

    def get(key)
      key_array = key.split('.')
      self.recursive_get(@tree, key_array)
    end

    def [](key)
      self.get(key)
    end

    def fetch(key, default_value = nil)
      ret = self.get(key)
      if ret.nil?
        if default_value.nil?
          raise KeyError.new(key)
        else
          return default_value
        end
      end
      ret
    end

    # Recursive perform an inject as in Ennumerable::inject, but
    # passing the path of the element with the syntax used
    # in BOSH opsfiles.
    def recursive_inject(acum, x, path)
      if x.is_a? Hash
        x.inject(acum) { |acum2, (key, x2)|
          recursive_inject(acum2, x2, path + '/' + key) { |acum3, x3, path3|
            yield(acum3, x3, path3)
          }
        }
      elsif x.is_a? Array
        x.each_with_index.inject(acum) { |acum2, (x2, index)|
          new_path = if x2.is_a?(Hash) && x2.has_key?('name')
                       path + '/name=' + x2['name']
                     else
                       path + '/' + index.to_s
                     end
          recursive_inject(acum2, x2, new_path) { |acum3, x3, path3|
            yield(acum3, x3, path3)
          }
        }
      else
        yield(acum, x, path)
      end
    end

    def inject(acum)
      self.recursive_inject(acum, @tree, "") { |acum2, x, path|
        yield(acum2, x, path)
      }
    end
  end

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
    render_manifest_with_vars_store(
      environment: "prod",
      enable_datadog: "false",
      disable_user_creation: "true",
      env_specific_manifest: "prod",
    )
  end

  def manifest_for_dev
    render_manifest_with_vars_store(
      environment: "dev",
      enable_datadog: "false",
      disable_user_creation: "true",
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
    copy_prom_uaa
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

    deep_freeze(PropertyTree.load_yaml(output))
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

    deep_freeze(PropertyTree.load_yaml(output))
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
    dir = workdir + '/environment-variables'
    FileUtils.mkdir(dir) unless Dir.exist?(dir)
    FileUtils.cp(
      root.join("manifests/shared/spec/fixtures/environment-variables.yml"),
      "#{dir}/environment-variables.yml",
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

  def copy_prom_uaa
    dir = workdir + '/prometheus-boshrelease/manifests/operators/cf'
    FileUtils.mkdir_p(dir) unless Dir.exist?(dir)
    FileUtils.cp(
      root.join("manifests/shared/spec/fixtures/add-prometheus-uaa-clients.yml"),
      "#{dir}/add-prometheus-uaa-clients.yml",
    )
  end

  def load_terraform_fixture
    data = YAML.load_file(root.join("manifests/shared/spec/fixtures/terraform/cf.yml"))
    deep_freeze(data)
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

  def deep_freeze(object)
    case object
    when Hash
      object.each { |_k, v| deep_freeze(v) }
    when Array
      object.each { |v| deep_freeze(v) }
    end
    object.freeze
  end
end

RSpec.configuration.include ManifestHelpers
