RSpec.describe 'prometheus' do
  let(:manifest) { manifest_with_defaults }

  let(:releases) { manifest.fetch('releases') }
  let(:instance_groups) { manifest.fetch('instance_groups') }

  let(:prometheus_instance_group) { manifest.fetch('instance_groups.prometheus') }
  let(:prometheus_config) do
    manifest.fetch('instance_groups.prometheus.jobs.prometheus2.properties.prometheus')
  end

  let(:route_registrar_routes)  do
    manifest.fetch('instance_groups.prometheus.jobs.route_registrar.properties.route_registrar.routes')
  end

  let(:caddy_config) do
    manifest.fetch('instance_groups.prometheus.jobs.caddy.properties')
  end

  context 'manifest' do
    it 'should have prometheus as a release' do
      release_names = releases.map { |r| r['name'] }
      expect(release_names).to include('prometheus')
    end

    it 'should have caddy as a release' do
      release_names = releases.map { |r| r['name'] }
      expect(release_names).to include('caddy')
    end

    it 'should have a prometheus instance group' do
      instance_group_names = instance_groups.map { |g| g['name'] }
      expect(instance_group_names).to include('prometheus')
    end
  end

  context 'instance_group' do
    it 'should have a persistent disk' do
      disk_type = prometheus_instance_group.dig('persistent_disk_type')
      expect(disk_type).to eq('100GB')
    end

    it 'should have more than one instance' do
      disk_type = prometheus_instance_group.dig('instances')
      expect(disk_type).to be > 0
    end

    it 'should have access to the CF network ' do
      network_names = prometheus_instance_group
        .dig('networks')
        .map { |n| n['name'] }
      expect(network_names).to include('cf')
    end
  end

  context 'prometheus2 job' do
    it 'should not have any rule_files configured' do
      expect(prometheus_config['rule_files']).to eq([])
    end

    it 'should scrape itself' do
      scrape_configs = prometheus_config['scrape_configs']
      prom_scrape_config = scrape_configs.find { |c| c['job_name'] == 'prometheus' }

      expect(prom_scrape_config).not_to be_nil
      expect(prom_scrape_config['static_configs']).to eq(
        [{ 'targets' => ['localhost:9090']}],
      )
    end
  end

  context 'route_registrar job' do
    it 'should register prometheus under the system domain' do
      prometheus_route = route_registrar_routes.find { |r| r['name'] == 'prometheus' }

      expect(prometheus_route).not_to be_nil
      expect(prometheus_route['port']).to eq(8080)
      expect(prometheus_route['prepend_instance_index']).to eq(false)
      expect(prometheus_route['uris']).to eq(
        ["prometheus.#{terraform_fixture_value(:cf_root_domain)}"],
      )
    end
  end

  context 'caddy job' do
    it 'should listen on port 8080' do
      http_port = caddy_config['http_port']
      expect(http_port).to eq(8080)
    end

    context 'caddyfile' do
      let(:caddyfile) {caddy_config['caddyfile']}

      it 'should listen on all interfaces' do
        # Caddy cannot just listen on localhost,
        # otherwise it will not proxy traffic from gorouter

        vhosts = caddyfile.gsub(/{.*}/m, '').lines.map(&:strip)
        expect(vhosts).to eq(['http://:8080'])
      end

      it 'should be configured without TLS' do
        # Caddy tries to infer what it should get a self-signed certificate
        # We want to disable this feature explicitly

        expect(caddyfile.lines.grep(/^\s+tls off/).first&.strip).to eq('tls off')
      end

      it 'should be configured for HA' do
        proxy_config = caddyfile
          .lines.grep(/^\s+proxy/).first
          .strip.sub(/^proxy/, '').sub(' {', '')

        proxy_listen, *proxy_hosts = proxy_config.split(' ')

        expect(proxy_listen).to eq('/')
        expect(proxy_hosts.first).to eq('http://q-s3-i0.prometheus.*.unit-test.bosh:9090')
        expect(proxy_hosts.last).to eq('http://localhost:9090')
      end
    end
  end
end
