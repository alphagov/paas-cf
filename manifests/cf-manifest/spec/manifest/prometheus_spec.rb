RSpec.describe "prometheus" do
  let(:manifest) { manifest_with_defaults }

  let(:releases) { manifest.fetch("releases") }
  let(:instance_groups) { manifest.fetch("instance_groups") }

  let(:prometheus_instance_group) { manifest.fetch("instance_groups.prometheus") }
  let(:prometheus_config) do
    manifest.fetch("instance_groups.prometheus.jobs.prometheus2.properties.prometheus")
  end

  let(:route_registrar_routes) do
    manifest.fetch("instance_groups.prometheus.jobs.route_registrar.properties.route_registrar.routes")
  end

  let(:caddy_config) do
    manifest.fetch("instance_groups.prometheus.jobs.caddy.properties")
  end

  let(:aiven_sd_config) do
    manifest.fetch("instance_groups.prometheus.jobs.aiven-service-discovery.properties")
  end

  describe "manifest" do
    it "has prometheus as a release" do
      release_names = releases.map { |r| r["name"] }
      expect(release_names).to include("prometheus")
    end

    it "has caddy as a release" do
      release_names = releases.map { |r| r["name"] }
      expect(release_names).to include("caddy")
    end

    it "has observability as a release" do
      release_names = releases.map { |r| r["name"] }
      expect(release_names).to include("observability")
    end

    it "has a prometheus instance group" do
      instance_group_names = instance_groups.map { |g| g["name"] }
      expect(instance_group_names).to include("prometheus")
    end
  end

  describe "instance_group" do
    it "has a persistent disk" do
      disk_type = prometheus_instance_group.dig("persistent_disk_type")
      expect(disk_type).to eq("500GB")
    end

    it "is highly available" do
      disk_type = prometheus_instance_group.dig("instances")
      expect(disk_type).to be > 1
    end

    it "has access to the CF network" do
      network_names = prometheus_instance_group
        .dig("networks")
        .map { |n| n["name"] }
      expect(network_names).to include("cf")
    end
  end

  describe "prometheus2 job" do
    it "does not have any rule_files configured" do
      expect(prometheus_config["rule_files"]).to eq([])
    end

    it "scrapes itself" do
      scrape_configs = prometheus_config["scrape_configs"]
      prom_scrape_config = scrape_configs.find { |c| c["job_name"] == "prometheus" }

      expect(prom_scrape_config).not_to be_nil
      expect(prom_scrape_config["static_configs"]).to eq(
        [{ "targets" => ["localhost:9090"] }],
      )
    end

    it "scrapes aiven" do
      scrape_configs = prometheus_config["scrape_configs"]
      aiven_scrape_config = scrape_configs.find { |c| c["job_name"] == "aiven" }

      expect(aiven_scrape_config).not_to be_nil

      expect(aiven_scrape_config["scheme"]).to eq("https")

      expect(aiven_scrape_config["tls_config"]).to eq(
        "insecure_skip_verify" => true, # We do IP based service discovery
      )

      expect(aiven_scrape_config["basic_auth"]).to eq(
        "username" => "((aiven_prometheus_username))",
        "password" => "((aiven_prometheus_password))",
      )

      targets = aiven_scrape_config["file_sd_configs"].first["files"].first

      expect(targets).to eq(
        aiven_sd_config["target_path"] + "/" + aiven_sd_config["target_filename"],
      )

      relabel_configs = aiven_scrape_config["relabel_configs"]

      expect(relabel_configs).to include(
        "source_labels" => %w[aiven_cloud],
        "separator" => ";",
        "regex" => "aws-sealand-1",
        "action" => "keep",
      )
    end

    it "has retention configured" do
      retention_time = prometheus_config.dig("storage", "tsdb", "retention", "time")
      retention_size = prometheus_config.dig("storage", "tsdb", "retention", "size")

      expect(retention_time).not_to be_nil
      expect(retention_size).not_to be_nil
    end

    describe "dropping metrics" do
      let(:dropped_metrics_regexps) do
        prometheus_config
          .dig("scrape_configs")
          .find { |sc| sc["job_name"] == "aiven" }
          .dig("relabel_configs")
          .select { |rlc| rlc["action"] == "drop" }
          .select { |rlc| rlc["source_labels"].include? "__name__" }
          .map { |rlc| rlc["regex"] }
          .reject(&:nil?)
          .map { |r| Regexp.new r }
      end

      it "drops metrics that we do not need" do
        %w[
          elasticsearch_breakers_parent_estimated_size_in_bytes
          elasticsearch_fs_io_stats_devices_0_write_operations
          elasticsearch_indices_indexing_delete_time_in_millis
          elasticsearch_os_cgroup_cpuacct_usage_nanos
          elasticsearch_thread_pool_warmer_threads
          net_icmp_inmsgs
          net_udplite_ignoredmulti
          prometheus_sd_consul_rpc_duration_seconds
          prometheus_sd_kubernetes_cache_watch_duration_seconds_sum
        ].each do |metric_to_drop|
          dropped_by = dropped_metrics_regexps.select { |r| r.match? metric_to_drop }
          expect(dropped_by).not_to(
            be_empty, "#{metric_to_drop} should not be kept"
          )
        end
      end

      it "does not drop metrics that we do not need" do
        %w[
          system_load1
          disk_used_percent
          diskio_reads
          diskio_writes
          mem_used_percent
          net_bytes_recv
          net_bytes_sent
          elasticsearch_clusterstats_indices_count
        ].each do |metric_to_keep|
          dropped_by = dropped_metrics_regexps.select { |r| r.match? metric_to_keep }
          expect(dropped_by).to(
            be_empty, "#{metric_to_keep} must not be dropped"
          )
        end
      end
    end

    it "has retention size less than the disk size" do
      disk_size_gb = prometheus_instance_group.dig("persistent_disk_type").gsub(/GB/, "").to_i
      retention_size = prometheus_config.dig("storage", "tsdb", "retention", "size")

      expect(retention_size.match?(/GB/)).to eq(true)
      retention_size_gb = retention_size.gsub(/GB/, "").to_i

      expect(retention_size_gb).to be < disk_size_gb
      expect(retention_size_gb).to be >= (disk_size_gb * 0.75)
    end

    it "has retention time greater than one year" do
      retention_time = prometheus_config.dig("storage", "tsdb", "retention", "time")

      expect(retention_time.match?(/\d+d$/)).to eq(true)
      retention_time_days = retention_time.gsub(/d$/, "").to_i

      expect(retention_time_days).to be > 365
    end
  end

  describe "route_registrar job" do
    it "registers prometheus under the system domain" do
      prometheus_route = route_registrar_routes.find { |r| r["name"] == "prometheus" }

      expect(prometheus_route).not_to be_nil
      expect(prometheus_route["port"]).to eq(8080)
      expect(prometheus_route["prepend_instance_index"]).to eq(false)
      expect(prometheus_route["uris"]).to eq(
        ["prometheus.#{terraform_fixture_value(:cf_root_domain)}"],
      )
    end
  end

  describe "caddy job" do
    it "listens on port 8080" do
      http_port = caddy_config["http_port"]
      expect(http_port).to eq(8080)
    end

    describe "caddyfile" do
      let(:caddyfile) { caddy_config["caddyfile"] }

      it "listens on all interfaces" do
        # Caddy cannot just listen on localhost,
        # otherwise it will not proxy traffic from gorouter

        vhosts = caddyfile.gsub(/{.*}/m, "").lines.map(&:strip)
        expect(vhosts).to eq(["http://:8080"])
      end

      it "is configured without TLS" do
        # Caddy tries to infer what it should get a self-signed certificate
        # We want to disable this feature explicitly

        expect(caddyfile.lines.grep(/^\s+tls off/).first&.strip).to eq("tls off")
      end

      it "is configured for HA" do
        proxy_config = caddyfile
          .lines.grep(/^\s+proxy/).first
          .strip.sub(/^proxy/, "").sub(" {", "")

        proxy_listen, *proxy_hosts = proxy_config.split(" ")

        expect(proxy_listen).to eq("/")
        expect(proxy_hosts.first).to eq("http://q-s3-i0.prometheus.*.unit-test.bosh:9090")
        expect(proxy_hosts.last).to eq("http://localhost:9090")
      end
    end
  end

  describe "aiven-service-discovery job" do
    it "has a project" do
      expect(aiven_sd_config.dig("aiven", "project")).to eq("paas-cf-dev")
    end

    it "has an api token" do
      expect(aiven_sd_config.dig("aiven", "api_token")).to eq("((aiven_api_token))")
    end
  end
end
