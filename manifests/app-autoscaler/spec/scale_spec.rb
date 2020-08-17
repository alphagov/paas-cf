RSpec.describe "scale" do
  let(:instance_groups) { manifest["instance_groups"] }

  describe "default" do
    let(:manifest) { manifest_with_defaults }

    it "is highly available" do
      instance_groups.each do |ig|
        instances = ig["instances"]
        expect(instances).to be > 1
      end
    end

    it "does not have vm_type nano" do
      instance_groups.each do |ig|
        expect(ig["vm_type"]).not_to be_nil
        expect(ig["vm_type"]).not_to eq("nano")
        expect(ig["vm_type"]).not_to eq("default")
      end
    end
  end

  describe "slim" do
    let(:manifest) { manifest = slim_manifest }

    it "is not highly available" do
      instance_groups.each do |ig|
        instances = ig["instances"]
        expect(instances).to be == 1, "#{ig["name"]} should be slim"
      end
    end

    it "has vm_type nano" do
      instance_groups.each { |ig| expect(ig["vm_type"]).to eq("nano") }
    end
  end
end
