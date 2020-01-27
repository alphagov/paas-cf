RSpec.describe 'isolation_segments' do
  context 'default' do
    let(:manifest) { manifest_with_defaults }

    let(:bosh_dns_cell_aliases) do
      manifest
        .fetch('addons.bosh-dns-aliases.jobs.bosh-dns-aliases.properties.aliases')
        .find { |a| a['domain'] == '_.cell.service.cf.internal' }
        .fetch('targets')
    end

    context 'dev-1' do
      let(:instance_group) { manifest.fetch('instance_groups.diego-cell-iso-seg-dev-1') }

      it 'is added to the manifest' do
        expect { instance_group }.not_to raise_error
      end

      it 'correctly gets a single instance' do
        expect(instance_group['instances']).to eq(1)
      end

      it 'correctly sets the vm_type when the size is changed' do
        expect(instance_group['vm_type']).to eq('small_cell')

        expect(
          instance_group
            .dig('jobs')
            .find { |j| j['name'] == 'rep' }
            .dig('properties', 'diego', 'executor', 'memory_capacity_mb')
        ).to eq(27197)
      end

      it 'has the correct placement tag' do
        expect(
          instance_group
            .dig('jobs')
            .find { |j| j['name'] == 'rep' }
            .dig('properties', 'diego', 'rep', 'placement_tags')
        ).to eq(['dev-1'])
      end

      it 'has an override for vxlan-policy-agent provider' do
        expect(
          instance_group
            .dig('jobs')
            .find { |j| j['name'] == 'vxlan-policy-agent' }
            .dig('provides')
        ).to eq('vpa' => { 'as' => 'vpa-dev-1' })
      end

      %w[silk-cni silk-daemon].each do |consumer|
        it "has an override for #{consumer} consumer" do
          expect(
            instance_group
              .dig('jobs')
              .find { |j| j['name'] == consumer }
              .dig('consumes')
          ).to eq('vpa' => { 'from' => 'vpa-dev-1' })
        end
      end

      it 'is added to bosh-dns-aliases for cells' do
        expect(bosh_dns_cell_aliases).to include(
          'query' => '_',
          'instance_group' => 'diego-cell-iso-seg-dev-1',
          'network' => 'cell',
          'deployment' => 'unit-test',
          'domain' => 'bosh'
        )
      end

      it 'should include the coredns job' do
        coredns_job = instance_group
          .dig('jobs')
          .find { |j| j['name'] == 'coredns' }

        expect(coredns_job).not_to be_nil
        expect(coredns_job['release']).to eq('observability')
        expect(coredns_job.dig('properties', 'corefile')).to match(
        <<~COREFILE
        .:53 {
          health :8054
          ready
          log
          prometheus :9153
          forward apps.internal 169.254.0.2:53
          bind 169.254.0.3
        }
        COREFILE
        )
      end

      it 'should set silk-cni dns_servers to be the local coredns resolver' do
        expect(
          instance_group
            .dig('jobs')
            .find { |j| j['name'] == 'silk-cni' }
            .dig('properties', 'dns_servers')
        ).to eq(['127.0.0.1'])
      end
    end

    context 'dev-2' do
      let(:instance_group) { manifest.fetch('instance_groups.diego-cell-iso-seg-dev-2') }

      it 'is added to the manifest' do
        expect { instance_group }.not_to raise_error
      end

      it 'correctly gets a zero instances' do
        expect(instance_group['instances']).to eq(0)
      end

      it 'does not override the default vm_type if it is not set' do
        expect(instance_group['vm_type']).to eq('cell')
      end

      it 'has the correct placement tag' do
        expect(
          instance_group
            .dig('jobs')
            .find { |j| j['name'] == 'rep' }
            .dig('properties', 'diego', 'rep', 'placement_tags')
        ).to eq(['dev-2'])
      end

      it 'has an override for vxlan-policy-agent provider' do
        expect(
          instance_group
            .dig('jobs')
            .find { |j| j['name'] == 'vxlan-policy-agent' }
            .dig('provides')
        ).to eq('vpa' => { 'as' => 'vpa-dev-2' })
      end

      it 'should not include the coredns job' do
        expect(
          instance_group
            .dig('jobs')
            .find { |j| j['name'] == 'coredns' }
        ).to be_nil
      end

      it 'should not set any silk-cni dns_servers' do
        expect(
          instance_group
            .dig('jobs')
            .find { |j| j['name'] == 'silk-cni' }
            .dig('properties', 'dns_servers')
        ).to be_nil
      end

      %w[silk-cni silk-daemon].each do |consumer|
        it "has an override for #{consumer} consumer" do
          expect(
            instance_group
              .dig('jobs')
              .find { |j| j['name'] == consumer }
              .dig('consumes')
          ).to eq('vpa' => { 'from' => 'vpa-dev-2' })
        end
      end

      it 'is added to bosh-dns-aliases for cells' do
        expect(bosh_dns_cell_aliases).to include(
          'query' => '_',
          'instance_group' => 'diego-cell-iso-seg-dev-2',
          'network' => 'cell',
          'deployment' => 'unit-test',
          'domain' => 'bosh'
        )
      end
    end
  end
end
