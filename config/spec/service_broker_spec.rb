require 'json'

CONFIG_FILES = Dir.glob(
  File.join(
    File.expand_path(
      File.join(__dir__, '..', 'service-brokers')
    ),
    '**', '*.json'
  )
)

AIVEN_JSON = File.read(CONFIG_FILES.grep(/aiven/).first)

describe 'service broker' do
  it 'should be valid json' do
    CONFIG_FILES.each do |f|
      contents = File.read(f)
      expect { JSON.parse(contents) }.not_to raise_exception,
        "#{f} is invalid JSON"
    end
  end

  describe 'aiven' do
    let(:services) { JSON.parse(AIVEN_JSON).dig('catalog', 'services') }
    let(:plans) { services.flat_map { |s| s['plans'] } }

    it 'should have description' do
      plans.each do |plan|
        expect(plan['description']).to be_a(String),
          "#{plan} needs a description"
      end
    end

    it 'should have version' do
      plans.each do |plan|
        version = plan.dig('metadata', 'AdditionalMetadata', 'version')
        expect(version).to be_a(String), "#{plan} needs a version, got #{version}"
      end
    end
  end
end
