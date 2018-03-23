require_relative '../../scripts/rotate-cf-certs.rb'

RSpec.describe "rotate-cf-certs" do
  let(:manifest) {
    YAML.safe_load <<EOS
variables:
- name: ca_one
  type: certificate
  options:
    is_ca: true
    common_name: internalCA
- name: ca_one_old
  type: certificate
  options:
    is_ca: true
    common_name: internalCA
- name: leaf_one
  type: certificate
  options:
    ca: ca_one
    common_name: leaf_one.cf.internal
- name: leaf_two
  type: certificate
  options:
    ca: ca_one
    common_name: leaf_two.cf.internal
EOS
  }

  describe "no certificates" do
    let(:certs) {
      {}
    }

    it "should return no certificates without raising exceptions" do
      expect(rotate(manifest, certs, ca: true, leaf: true)).to eq(certs)
    end
  end

  describe "CA certificates" do
    let(:certs) {
      YAML.safe_load <<EOS
ca_one:
  ca: |
    one
  certificate: |
    one
  private_key: |
    one
ca_one_old:
  ca: |
    two
  certificate: |
    two
  private_key: |
    two
EOS
    }

    describe "ca false" do
      it "should not change CA certificates" do
        expect(rotate(manifest, certs)).to eq(certs)
      end
    end

    describe "ca true" do
      it "should copy existing cert to _old and delete original so that it can be regenerated" do
        expect(rotate(manifest, certs, ca: true)).to eq(YAML.safe_load(<<EOS
ca_one_old:
  ca: |
    one
  certificate: |
    one
  private_key: |
    one
EOS
        ))
      end
    end
  end

  describe "leaf certificates" do
    let(:certs) {
      YAML.safe_load <<EOS
leaf_one:
  ca: |
    one
  certificate: |
    one
  private_key: |
    one
leaf_two:
  ca: |
    two
  certificate: |
    two
  private_key: |
    two
EOS
    }

    describe "leaf false" do
      it "should not change leaf certificates" do
        expect(rotate(manifest, certs)).to eq(certs)
      end
    end

    describe "leaf true" do
      it "should delete existing certs so they can be regenerated" do
        expect(rotate(manifest, certs, leaf: true)).to eq({})
      end
    end
  end

  describe "delete true" do
    let(:certs) {
      YAML.safe_load <<EOS
ca_one:
  ca: |
    one
  certificate: |
    one
  private_key: |
    one
ca_one_old:
  ca: |
    two
  certificate: |
    two
  private_key: |
    two
leaf_one:
  ca: |
    one
  certificate: |
    one
  private_key: |
    one
EOS
    }

    it "should blank existing _old certs so that they are not regenerated" do
      expect(rotate(manifest, certs, delete: true)).to eq(YAML.safe_load(<<EOS
ca_one:
  ca: |
    one
  certificate: |
    one
  private_key: |
    one
ca_one_old:
  ca: ""
  certificate: ""
  private_key: ""
leaf_one:
  ca: |
    one
  certificate: |
    one
  private_key: |
    one
EOS
      ))
    end
  end
end
