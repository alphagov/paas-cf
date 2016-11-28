require 'securerandom'
require 'openssl'
require 'digest/md5'

class SecretGenerator
  PASSWORD_PREFIX = 'p'.freeze
  PASSWORD_LENGTH = 18

  def self.random_password
    bytes = PASSWORD_LENGTH / 2
    PASSWORD_PREFIX + SecureRandom.hex(bytes)
  end

  def self.sha512_crypt(password, salt = nil)
    salt ||= SecureRandom.urlsafe_base64(16 * 3 / 4)
    # '$6$' causes crypt to use SHA-512
    # See the crypt(3) manpage (on a glibc based OS) for more details
    password.crypt("$6$#{salt}")
  end

  def self.generate_ssh_key
    key = OpenSSL::PKey::RSA.new(2048)
    {
      "private_key" => key.to_pem,
      "public_fingerprint" => ssh_key_md5_fingerprint(key.public_key),
    }
  end

  def initialize(required_secrets)
    @required_secrets = required_secrets
    @existing_secrets = {}
  end

  attr_accessor :existing_secrets

  def generate
    @required_secrets.each_with_object({}) do |(key, type), output|
      # If a secret exists and is not nil or empty, keep it rather than
      # generating a new one. This checks that existing_secrets is a hash
      # because if the secrets key in the yaml file exists but is empty we'll
      # get nil.
      if existing_secrets.is_a?(Hash) && !([nil, ''].include? @existing_secrets.fetch(key, nil))
        # Special case for keeping the original uncrypted password
        if type == :sha512_crypted
          output["#{key}_orig"] = @existing_secrets["#{key}_orig"]
        end

        output[key] = @existing_secrets[key]
        next
      end

      case type
      when :simple
        output[key] = self.class.random_password
      when :simple_in_array
        output[key] = [self.class.random_password]
      when :sha512_crypted
        output["#{key}_orig"] = self.class.random_password
        output[key] = self.class.sha512_crypt(output["#{key}_orig"])
      when :ssh_key
        output[key] = self.class.generate_ssh_key
      else
        raise ArgumentError, "unrecognized secret type '#{type}'"
      end
    end
  end

  # This method lifted from 1.8.0 of the sshkey gem.
  # https://github.com/bensie/sshkey/blob/1.8.0/lib/sshkey.rb#L346
  # combined with
  # https://github.com/bensie/sshkey/blob/1.8.0/lib/sshkey.rb#L253
  def self.ssh_key_md5_fingerprint(public_key)
    methods = %w(e n)
    public_key_str = methods.inject([7].pack("N") + "ssh-rsa") do |pubkeystr, m|
      # Given pubkey.class == OpenSSL::BN, pubkey.to_s(0) returns an MPI
      # formatted string (length prefixed bytes). This is not supported by
      # JRuby, so we still have to deal with length and data separately.
      val = public_key.send(m)

      # Get byte-representation of absolute value of val
      data = val.to_s(2)

      first_byte = data[0, 1].unpack("c").first
      if val < 0
        # For negative values, highest bit must be set
        data[0] = [0x80 & first_byte].pack("c")
      elsif first_byte < 0
        # For positive values where highest bit would be set, prefix with \0
        data = "\0" + data
      end
      pubkeystr + [data.length].pack("N") + data
    end

    Digest::MD5.hexdigest(public_key_str).gsub(/(.{2})(?=.)/, '\1:\2')
  end
end
