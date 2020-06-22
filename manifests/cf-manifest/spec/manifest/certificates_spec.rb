RSpec.describe "certificates" do
  def get_all_cas_usages(o)
    return o.flat_map { |v| get_all_cas_usages(v) } if o.is_a? Array

    if o.is_a? Hash
      # Match checks if it is a usage ("name.value") or a variable ("name")
      return [o["ca"]] if o["ca"]&.match?(/[.]/)
      return [o["ca_cert"]] if o["ca_cert"]&.match?(/[.]/)

      return o.values.flat_map { |v| get_all_cas_usages(v) }
    end

    []
  end

  describe "ca certificates" do
    let(:manifest) { manifest_with_defaults }

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
end
