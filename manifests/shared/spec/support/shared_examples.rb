RSpec.shared_examples "a highly available instance group" do |opts|
  let(:instances) { subject.dig("instances") }

  it "has instances defined" do
    expect(instances).not_to be_nil
  end

  it "is highly available" do
    expect(instances).to be >= 2
  end

  unless opts[:min_instances].nil?
    it "has more instances than the minimum" do
      expect(instances).to be >= opts[:min_instances]
    end
  end
end

RSpec.shared_examples "a cf rds client" do
  let(:vm_extensions) { subject.fetch("vm_extensions", []) }

  it "has the cf rds client security group" do
    expect(vm_extensions).to include("cf_rds_client_sg").or include("cf_cc_security_groups")
  end
end
