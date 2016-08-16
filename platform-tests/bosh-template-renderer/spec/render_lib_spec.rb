require 'yaml'
require './render_lib.rb'

RSpec.describe "Hash" do
  describe 'dig functions' do
    let(:example_hash) {
      { 'a' => { 'b' => { 'c' => 'foo' } } }
    }

    it 'retrieves a existing key' do
      expect(example_hash.dig('a.b.c')).to eq('foo')
    end

    it 'returns nil for non-existing keys' do
      expect(example_hash.dig('a.b.d')).to be_nil
      expect(example_hash.dig('a.d.c')).to be_nil
    end

    it 'populates a value to a key' do
      expect(example_hash.dig_add('a.y.x', 'bar')).to eq('bar')
      expect(example_hash.dig('a.y.x')).to eq('bar')
    end

    it 'replaces a value' do
      expect(example_hash.dig_add('a.b.c', 'foobar')).to eq('foobar')
      expect(example_hash.dig('a.b.c')).to eq('foobar')
    end
  end

  describe "merge functions" do
    let(:example_manifest) {
      {
        'properties' =>
          { 'a' =>
            { 'b' =>
              { 'c' => 'foo' }
            }
          }
      }
    }

    let(:example_spec) {
      {
        'properties' => {
          'a.b.c' => { 'default' => 'bar' },
          'a.b.d' => { 'default' => 'foobar' },
          'x.y.z' => {}
        }
      }
    }

    it 'does not overwrite an exiting value' do
      example_manifest.populate_default_properties_from_spec(example_spec)
      expect(example_manifest.dig('properties.a.b.c')).to eq('foo')
    end

    it 'populates a missing value with the default' do
      example_manifest.populate_default_properties_from_spec(example_spec)
      expect(example_manifest.dig('properties.a.b.d')).to eq('foobar')
    end

    it 'does not populate a missing value if there is no default in the spec' do
      example_manifest.populate_default_properties_from_spec(example_spec)
      expect(example_manifest.dig('properties.x.y.z')).to be_nil
    end
  end
end

RSpec.describe "render_template" do
  let(:example_spec) {
    %{
---
properties:
  a.b.c:
    description: Some property
    default: bar
  a.b.d:
    description: Some other property
    default: foobar
  x.y.z:
    description: And other property
    }
  }

  let(:example_manifest) {
    %{
---
properties:
  a:
    b:
      c: foo
  d: x
jobs:
- instances: 1
  name: job1
  properties:
    d: y
    }
  }

  it "renders from a template with defined and default values" do
    template = "a.b.c is <%= p('a.b.c') %> and a.b.d is <%= p('a.b.d') %>"
    result = render_template(template, YAML.load(example_spec), YAML.load(example_manifest))
    expect(result).to eq("a.b.c is foo and a.b.d is foobar")
  end

  it "does not override a false value with the default" do
    template = "a.b.c is <%= p('a.b.c') %> and a.b.d is <%= p('a.b.d') %>"
    example_manifest_with_false = example_manifest.sub('foo', 'false')
    result = render_template(template, YAML.load(example_spec), YAML.load(example_manifest_with_false))
    expect(result).to eq("a.b.c is false and a.b.d is foobar")
  end

  it "uses a normalised version of the manifest which allows discover external_ip" do
    template = %q{<%
def discover_external_ip
  networks = spec.networks.marshal_dump
  _, network = networks.find do |_name, network_spec|
    network_spec.default
  end
  if !network
    _, network = networks.first
  end
  if !network
    raise "Could not determine IP via network spec: #{networks}"
  end
  network.ip
end %>
a.b.c is <%= p('a.b.c') %> and a.b.d is <%= p('a.b.d') %> and the ip is <%= discover_external_ip %>
    }
    result = render_template(template, YAML.load(example_spec), YAML.load(example_manifest))
    expect(result).to include("a.b.c is foo and a.b.d is foobar and the ip is 127.0.0.1")
  end

  it "renders from a template with overriding job properties" do
    template = "d is <%= p('d') %>"
    result = render_template(template, YAML.load(example_spec), YAML.load(example_manifest), "job1")
    expect(result).to eq("d is y")
  end
end
