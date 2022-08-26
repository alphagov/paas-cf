RSpec.describe "certificates" do
  let(:manifest) { manifest_with_defaults }

  def get_all_cas_usages(enumerable)
    return enumerable.flat_map { |v| get_all_cas_usages(v) } if enumerable.is_a? Array

    if enumerable.is_a? Hash
      # Match checks if it is a usage ("name.value") or a variable ("name")
      return [enumerable["ca"]] if enumerable["ca"]&.match?(/[.]/)
      return [enumerable["ca_cert"]] if enumerable["ca_cert"]&.match?(/[.]/)

      return enumerable.values.flat_map { |v| get_all_cas_usages(v) }
    end

    []
  end

  describe "ca certificates" do
    let(:ca_usages) do
      get_all_cas_usages(manifest.fetch(".")).map do |usage|
        usage.gsub(/[()]/, "") # delete surrounding parens
      end
    end

    it "detects some ca certificate usages" do
      expect(ca_usages).not_to eq([])
    end

    it "uses .ca for every usage of a ca certificate" do
      expect(ca_usages).to all(match(/[.]ca$/)),
        "Usage of CA #{ca_usages} should be cert_name.ca not ca_name.certificate, otherwise credhub rotation will fail"
    end
  end

  describe "leaf certs" do
    let(:vars) { manifest.fetch("variables") }
    let(:certs) { vars.select { |v| v["type"] == "certificate" } }

    it "have at least one alternative_name" do
      certs.each do |c|
        is_ca = c.dig("options", "is_ca") || false

        if is_ca
          next
        end

        cert_name = c["name"]
        common_name = c.dig("options", "common_name")
        alt_names = c.dig("options", "alternative_names") || []

        if cert_name == "policy_server_asg_syncer_cc_client"
          # This is a special case, see https://github.com/cloudfoundry/cf-deployment/pull/985

          expect(alt_names.length).to eq(0),
            "policy_server_asg_syncer_cc_client does not have an alternative_name set in cloudfoundry/cf-deployment. When this test starts failing, remove this if statement."
          next
        end

        expect(alt_names.length).to be > 0,
          "Certificate #{cert_name} (common_name '#{common_name}') must have at least one alternative_name"
      end
    end
  end
end
