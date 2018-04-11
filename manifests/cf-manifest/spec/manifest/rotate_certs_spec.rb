RSpec.describe "Certificate rotation" do
  let(:manifest) { manifest_without_vars_store }

  it "uses the current and old certificate for every CA certificate" do
    ca_certs = manifest.fetch('variables').inject([]) { |a, v|
      if v.fetch('options', {}).fetch('is_ca', false)
        a + [v['name']]
      else
        a
      end
    }
    rotable_ca_certs = ca_certs.select { |v|
      ca_certs.include?(v + '_old')
    }

    rotable_ca_certs_not_patched = manifest.inject([]) { |acum, v, path|
      new_acum = acum
      if v =~ /\(\(([^\.]*).certificate\)\)/
        cert_name = $1
        if rotable_ca_certs.include?(cert_name)
          unless v =~ /\(\(#{cert_name}.certificate\)\)\(\(#{cert_name}_old.certificate\)\)/
            new_acum << path
          end
        end
      end
      new_acum
    }

    expect(rotable_ca_certs_not_patched).to be_empty,
      "CA certificates missing the '_old.certificate' to support rotation: #{rotable_ca_certs_not_patched.join('; ')}"
  end
end
