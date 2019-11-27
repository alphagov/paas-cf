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

  context 'manifest' do
    it 'should have prometheus as a release' do
      release_names = releases.map { |r| r['name'] }
      expect(release_names).to include('prometheus')
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
      expect(prometheus_route['port']).to eq(9090)
      expect(prometheus_route['prepend_instance_index']).to eq(true)
      expect(prometheus_route['uris']).to eq(
        ["prometheus.#{terraform_fixture_value(:cf_root_domain)}"],
      )
    end
  end
end
