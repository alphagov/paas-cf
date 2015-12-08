
RSpec.describe "base properties" do
  let(:manifest) { manifest_with_defaults }
  let(:properties) { manifest.fetch("properties") }

  describe "cloud controller" do
    subject(:cc) { properties.fetch("cc") }

    shared_examples "a component with an AWS connection" do
      let(:fog_connection) { subject.fetch("fog_connection") }

      specify { expect(fog_connection).to include("aws_access_key_id" => terraform_fixture("aws_access_key_id")) }
      specify { expect(fog_connection).to include("aws_secret_access_key" => terraform_fixture("aws_secret_access_key")) }
      specify { expect(fog_connection).to include("region" => terraform_fixture(:region)) }
      specify { expect(fog_connection).to include("provider" => "AWS") }
    end

    describe "buildpacks" do
      subject(:buildpacks) { cc.fetch("buildpacks") }

      it_behaves_like "a component with an AWS connection"
    end

    describe "droplets" do
      subject(:droplets) { cc.fetch("droplets") }

      it_behaves_like "a component with an AWS connection"
    end

    describe "packages" do
      subject(:packages) { cc.fetch("packages") }

      it_behaves_like "a component with an AWS connection"
    end

    describe "resource_pool" do
      subject(:resource_pool) { cc.fetch("resource_pool") }

      it_behaves_like "a component with an AWS connection"
    end
  end
end
