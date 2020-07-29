require "ipaddr"

DeploymentReference = Struct.new(:deployment, :path)

def deployment_refs(frag, path)
  return [] if frag.is_a?(TrueClass) || frag.is_a?(FalseClass)
  return [] if frag.nil? || frag.is_a?(String) || frag.is_a?(Numeric)
  return frag.map.with_index { |c, i| deployment_refs(c, "#{path}/#{i}") }.flatten if frag.is_a?(Array)

  if frag.key? "deployment"
    return [DeploymentReference.new(frag["deployment"], "#{path}/deployment")]
  end

  frag.map { |k, c| deployment_refs(c, "#{path}/#{k}") }.flatten
end

RSpec.describe "autoscaler" do
  let(:manifest) { manifest_with_defaults }
  let(:valid_deployments) { %w[test app-autoscaler] }

  describe "addons" do
    let(:refs) { deployment_refs(manifest["addons"], "") }

    it "references a valid deployment" do
      refs.each do |ref|
        err_msg = "#{ref.path} does not reference a valid deployment #{valid_deployments}"
        expect(valid_deployments).to include(ref.deployment), err_msg
      end
    end
  end

  describe "instance groups" do
    let(:refs) { deployment_refs(manifest["instance_groups"], "") }

    it "references a valid deployment" do
      refs.each do |ref|
        err_msg = "#{ref.path} does not reference a valid deployment #{valid_deployments}"
        expect(valid_deployments).to include(ref.deployment), err_msg
      end
    end
  end
end
