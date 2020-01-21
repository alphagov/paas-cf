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

      it 'does not override the default vm_type if it is not set' do
        expect(instance_group['vm_type']).to eq('cell')
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
    end

    context 'dev-2' do
      let(:instance_group) { manifest.fetch('instance_groups.diego-cell-iso-seg-dev-2') }

      it 'is added to the manifest' do
        expect { instance_group }.not_to raise_error
      end

      it 'correctly gets a zero instances' do
        expect(instance_group['instances']).to eq(0)
      end

      it 'correctly sets the vm_type' do
        expect(instance_group['vm_type']).to eq('small')
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
