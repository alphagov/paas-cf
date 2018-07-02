require_relative '../../scripts/rotate-vars-store-secrets.rb'

RSpec.describe "rotate-cf-certs" do
  let(:manifest) {
    YAML.safe_load <<EOS
variables:
- name: ca_one
  type: certificate
  options:
    is_ca: true
    common_name: internalCA1
- name: ca_one_old
  type: certificate
  options:
    is_ca: true
    common_name: internalCA1
- name: ca_two
  type: certificate
  options:
    is_ca: true
    common_name: internalCA2
- name: ca_to_keep
  type: certificate
  options:
    is_ca: true
    common_name: internalCA3
- name: leaf_one
  type: certificate
  options:
    ca: ca_one
    common_name: leaf_one.cf.internal
- name: leaf_one_old
  type: certificate
  options:
    ca: ca_one
    common_name: leaf_one.cf.internal
- name: leaf_two
  type: certificate
  options:
    ca: ca_one
    common_name: leaf_two.cf.internal
- name: leaf_to_keep
  type: certificate
  options:
    ca: ca_one
    common_name: leaf_to_keep.cf.internal
- name: passwords_one
  type: password
- name: passwords_one_old
  type: password
- name: passwords_two
  type: password
- name: passwords_to_keep
  type: password
- name: ssh_one
  type: ssh
- name: ssh_one_old
  type: ssh
- name: ssh_to_keep
  type: ssh
- name: ssh_two
  type: ssh
- name: rsa_one
  type: rsa
- name: rsa_one_old
  type: rsa
- name: rsa_two
  type: rsa
- name: rsa_to_keep
  type: rsa

EOS
  }

  let(:empty_vars_store) {
    {}
  }

  let(:vars_store) {
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
ca_to_keep:
  ca: |
    to_keep
  certificate: |
    to_keep
  private_key: |
    to_keep
ca_two:
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
leaf_one_old:
  ca: |
    one_old
  certificate: |
    one_old
  private_key: |
    one_old
leaf_one_to_keep:
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
passwords_one: foo
passwords_one_old: foo_old
passwords_two: foo2
passwords_to_keep: foo_keep
rsa_one:
  private_key: rsa_priv
  public_key: rsa_pub
rsa_one_old:
  private_key: rsa_priv_old
  public_key: rsa_pub_old
rsa_two:
  private_key: rsa_priv2
  public_key: rsa_pub2
rsa_to_keep:
  private_key: rsa_priv_keep
  public_key: rsa_pub_keep
ssh_one:
  private_key: Private key
  public_key: Public key
  public_key_fingerprint: Public key's MD5 fingerprint
ssh_one_old:
  private_key: Private key old
  public_key: Public key old
  public_key_fingerprint: Public key's MD5 fingerprint old
ssh_two:
  private_key: Private key 2
  public_key: Public key 2
  public_key_fingerprint: Public key's MD5 fingerprint 2
ssh_to_keep:
  private_key: Private key keep
  public_key: Public key keep
  public_key_fingerprint: Public key's MD5 fingerprint keep
EOS
  }

  let(:vars_to_preserve) {
    %w{
      ca_to_keep
      leaf_to_keep
      passwords_to_keep
      rsa_to_keep
      ssh_to_keep
    }
  }

  describe "no variables" do
    it "should return no variables without raising exceptions" do
      expect(rotate(manifest,
                    empty_vars_store,
                    ca: true,
                    leaf: true,
                    passwords: true,
                    rsa: true,
                    ssh: true,)).to eq(empty_vars_store)
    end
  end

  %w{
    ca
    leaf
    passwords
    rsa
    ssh
  }.each do |type|

    describe "#{type} type secrets" do
      it "should not change if #{type}: false" do
        expect(rotate(manifest, vars_store)).to eq(vars_store)
      end

      it "should delete existing passwords so they can be regenerated" do
        # Build a call like: rotate(manifest , ca: true, vars_to_preserve: vars_to_preserve)
        args = {
          type.to_sym => true,
          vars_to_preserve: vars_to_preserve,
        }
        rotated_vars_store = rotate(manifest, vars_store, **args)

        expect(rotated_vars_store).to_not include("#{type}_one")
        expect(rotated_vars_store).to_not include("#{type}_two")

        remaining_secrets = vars_store.keys.reject { |k| (k == "#{type}_one") || (k == "#{type}_two") }
        expect(rotated_vars_store.keys).to include(*remaining_secrets)

        expect(rotated_vars_store).to include("#{type}_one_old" => vars_store["#{type}_one"])
      end
    end
  end

  describe "delete true" do
    it "should delete _old secrets that are not certs" do
      rotated_vars_store = rotate(manifest, vars_store, delete: true)

      rotated_vars_store.each { |k, _v|
        unless (k.start_with? "ca_", "leaf_") && k.end_with?("_old")
          expect(k).to_not end_with "_old"
        end
      }
    end

    it "should ablank existing _old certs so that they are not regenerated and kept empty" do
      rotated_vars_store = rotate(manifest, vars_store, delete: true)

      rotated_vars_store.each { |k, v|
        if (k.start_with? "ca_", "leaf_") && k.end_with?("_old")
          expect(v).to include(
            "ca" => "",
            "certificate" => "",
            "private_key" => "",
          )
        end
      }
    end
  end
end
