
require 'secret_generator'

RSpec.describe SecretGenerator do
  SIMPLE_PASSWORD_REGEX = /\A[a-zA-Z0-9]+\z/

  describe "password generation" do
    it "prefixes the password with a fixed character" do
      pw = SecretGenerator.random_password
      expect(pw).to start_with(SecretGenerator::PASSWORD_PREFIX)
    end

    it "generates a passwords of the required length" do
      pw = SecretGenerator.random_password
      expect(pw.size).to eq(SecretGenerator::PASSWORD_LENGTH + SecretGenerator::PASSWORD_PREFIX.size)
    end

    it "generates a different password each time" do
      passwords = 10.times.map { |_| SecretGenerator.random_password }
      duplicated_passwords = passwords.select { |n| passwords.count(n) > 1 }.uniq
      expect(duplicated_passwords).to be_empty,
        "Duplicate passwords generated (#{duplicated_passwords.join(',')} generated more than once)"
    end

    it "only uses alphanumeric characters" do
      10.times do
        expect(SecretGenerator.random_password).to match(SIMPLE_PASSWORD_REGEX)
      end
    end
  end

  describe "sha512_crypt" do
    # expectations generated with
    # `echo 'sample_password' | mkpasswd -s -m sha-512 -S saltysaltysalty`
    let(:password) { "sample_password" }
    let(:salt) { "saltysaltysalty" }
    let(:expected_hash) { "$6$saltysaltysalty$50J9RJ/77gabvLQnqIxwnwTWFBWNx01w7/SNxJ14UsY9s7ZpETjf2DIUilzYjc0w0XQfcu1OMRnr1YSR/7Rd41" }

    it "generates a crypt style SHA512 hash of the given password" do
      skip "No sha support in crypt(3) on Mac OS X" if RUBY_PLATFORM =~ /darwin/
      actual_hash = SecretGenerator.sha512_crypt(password, salt)
      expect(actual_hash).to eq(expected_hash)
    end
  end

  describe "ssh key generation" do
    let(:ssh_key_fixture) {
      fixture_file = File.expand_path("../fixtures/sample_key", __FILE__)
      OpenSSL::PKey::RSA.new(File.read(fixture_file))
    }
    before(:each) do
      allow(OpenSSL::PKey::RSA).to receive(:new).and_return(ssh_key_fixture)
    end

    let(:generated_key) { SecretGenerator.generate_ssh_key }

    it "should return a PEM encoded private SSH key" do
      expect(generated_key).to include(
        "private_key" => ssh_key_fixture.to_pem,
      )
    end

    it "should return the fingerprint of the public key" do
      # expected fingerprint generated with `ssh-keygen -lf fixtures/sample_key.pub`
      expect(generated_key).to include(
        "public_fingerprint" => "ce:f2:03:7f:22:3e:c5:ec:18:b8:c0:70:b5:42:91:e7",
      )
    end
  end

  describe "generating required passwords" do
    it "generates the requested simple passwords" do
      required_secrets = {
        "foo" => :simple,
        "bar" => :simple,
      }
      results = SecretGenerator.new(required_secrets).generate

      expect(results["foo"]).to match(SIMPLE_PASSWORD_REGEX)
      expect(results["bar"]).to match(SIMPLE_PASSWORD_REGEX)
      expect(results["foo"]).not_to eq(results["bar"])
    end

    it "generates a one-element array of passwords when requested" do
      required_secrets = {
        "some_encrypt_keys" => :simple_in_array,
      }
      results = SecretGenerator.new(required_secrets).generate


      expect(results["some_encrypt_keys"]).to be_a(Array)
      expect(results["some_encrypt_keys"].size).to eq(1)
      expect(results["some_encrypt_keys"].first).to match(SIMPLE_PASSWORD_REGEX)
    end

    it "generates ssh keys when requested" do
      required_secrets = {
        "test_host_key" => :ssh_key,
      }
      results = SecretGenerator.new(required_secrets).generate

      expect(results["test_host_key"]).to be_a(Hash)
      expect(results["test_host_key"].keys).to match_array(%w(private_key public_fingerprint))
      expect(results["test_host_key"]["private_key"]).to include("-----BEGIN RSA PRIVATE KEY-----")
    end

    it "errors when given an unrecognized password type" do
      required_secrets = {
        "foo" => :whatever,
      }
      expect {
        SecretGenerator.new(required_secrets).generate
      }.to raise_error(ArgumentError)
    end

    describe "generating sha_512 crypted passwords" do
      let(:required_secrets) {
        {
        "baz" => :sha512_crypted,
      }}
      let(:results) { SecretGenerator.new(required_secrets).generate }

      it "places the simple password in an _orig key" do
        expect(results).to have_key("baz_orig")
        expect(results["baz_orig"]).to match(SIMPLE_PASSWORD_REGEX)
      end

      it "places the sha_512 crypted version in the requested key" do
        allow(SecretGenerator).to receive(:sha512_crypt) { |pw| "crypted_#{pw}" }

        expect(results).to have_key("baz")
        expect(results["baz"]).to eq("crypted_#{results['baz_orig']}")
      end
    end

    it "generates a mixture of types" do
      required_secrets = {
        "simple1" => :simple,
        "simple2" => :simple,
        "array" => :simple_in_array,
        "crypted" => :sha512_crypted,
        "simple3" => :simple,
        "host_key" => :ssh_key,
      }
      results = SecretGenerator.new(required_secrets).generate

      expect(results.keys).to match_array(%w(simple1 simple2 simple3 array crypted crypted_orig host_key))
    end
  end

  describe "merging with existing passwords" do
    let(:required_secrets) {
      {
      "simple1" => :simple,
      "simple2" => :simple,
      "array" => :simple_in_array,
      "crypted" => :sha512_crypted,
      "host_key" => :ssh_key,
    }}
    let(:generator) { SecretGenerator.new(required_secrets) }

    it "keeps simple passwords from the existing set" do
      generator.existing_secrets = {
        "simple1" => "something",
      }
      results = generator.generate

      expect(results["simple1"]).to eq("something")
    end

    it "keeps array passwords from the existing set" do
      generator.existing_secrets = {
        "array" => ["something"],
      }
      results = generator.generate

      expect(results["array"]).to eq(["something"])
    end

    it "keeps crypted passwords from the existing set" do
      generator.existing_secrets = {
        "crypted" => "something_crypted",
        "crypted_orig" => "something",
      }
      results = generator.generate

      expect(results["crypted"]).to eq("something_crypted")
      expect(results["crypted_orig"]).to eq("something")
    end

    it "keeps ssh keys from the existing set" do
      generator.existing_secrets = {
        "host_key" => { "private_key" => "1234", "public_fingerprint" => "2345" },
      }
      results = generator.generate

      expect(results["host_key"]["private_key"]).to eq("1234")
      expect(results["host_key"]["public_fingerprint"]).to eq("2345")
    end

    it "removes passwords in the existing set that aren't in the requested set" do
      generator.existing_secrets = {
        "other" => "something",
      }
      results = generator.generate

      expect(results).not_to have_key("other")
    end

    it "generates empty paswords in the existing set that are in the required set" do
      generator.existing_secrets = {
        "simple1" => "",
        "simple2" => nil,
      }
      results = generator.generate

      expect(results["simple1"]).to match(SIMPLE_PASSWORD_REGEX)
      expect(results["simple2"]).to match(SIMPLE_PASSWORD_REGEX)
    end

    it "generates all the required secrets if existing_secrets is nil" do
      required_secrets = {
        "foo" => :simple,
        "bar" => :simple,
      }
      generator = SecretGenerator.new(required_secrets)
      generator.existing_secrets = nil
      results = generator.generate

      expect(results.keys).to match_array(%w(foo bar))
    end
  end
end
