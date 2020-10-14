RSpec.describe "high availability" do
  let(:all_groups) { manifest.fetch("instance_groups") }
  let(:perm_groups) { all_groups.reject { |i| i["lifecycle"] == "errand" } }

  let(:brokers) { perm_groups.select { |i| i["name"] =~ /broker/ } }

  let(:non_brokers) do
    perm_groups
      .reject { |i| i["name"] =~ /broker/ }
      .reject { |i| i["name"] == "prometheus" }
      .reject { |i| i["name"] =~ /^diego-cell-iso-seg-/ }
  end

  describe "london" do
    let(:manifest) { manifest_for_env("prod-lon") }

    describe "non-brokers" do
      it "ensures all instance groups are highly available >= 3" do
        small_groups = non_brokers.select { |i| i["instances"] < 3 }
        names = small_groups.map { |i| i["name"] }
        expect(small_groups).to be_empty, "#{names} should have >= 3 instances"
      end
    end

    describe "brokers" do
      it "ensures all instance groups are highly available >= 2" do
        small_groups = brokers.select { |i| i["instances"] < 2 }
        names = small_groups.map { |i| i["name"] }
        expect(small_groups).to be_empty, "#{names} should have >= 2 instances"
      end
    end
  end

  describe "ireland" do
    let(:manifest) { manifest_for_env("prod") }

    describe "non-brokers" do
      it "ensures all instance groups are highly available >= 3" do
        small_groups = non_brokers.select { |i| i["instances"] < 3 }
        names = small_groups.map { |i| i["name"] }
        expect(small_groups).to be_empty, "#{names} should have >= 3 instances"
      end
    end

    describe "brokers" do
      it "ensures all instance groups are highly available >= 2" do
        small_groups = brokers.select { |i| i["instances"] < 2 }
        names = small_groups.map { |i| i["name"] }
        expect(small_groups).to be_empty, "#{names} should have >= 2 instances"
      end
    end
  end
end
