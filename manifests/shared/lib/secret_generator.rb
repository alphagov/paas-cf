require 'securerandom'

class SecretGenerator
  PASSWORD_LENGTH = 12

  def self.random_password
    bytes = PASSWORD_LENGTH * 3 / 4
    SecureRandom.urlsafe_base64(bytes)
  end

  def self.sha512_crypt(password, salt = nil)
    salt ||= SecureRandom.urlsafe_base64(16 * 3 / 4)
    # '$6$' causes crypt to use SHA-512
    # See the crypt(3) manpage (on a glibc based OS) for more details
    password.crypt("$6$#{salt}")
  end

  def initialize(required_secrets)
    @required_secrets = required_secrets
    @existing_secrets = {}
  end

  attr_accessor :existing_secrets

  def generate
    @required_secrets.each_with_object({}) do |(key, type), output|
      case type
      when :simple
        output[key] = @existing_secrets.fetch(key) { self.class.random_password }
      when :simple_in_array
        output[key] = @existing_secrets.fetch(key) { [self.class.random_password] }
      when :sha512_crypted
        if @existing_secrets.has_key?(key)
          output["#{key}_orig"] = @existing_secrets.fetch("#{key}_orig")
          output[key] = @existing_secrets[key]
        else
          output["#{key}_orig"] = self.class.random_password
          output[key] = self.class.sha512_crypt(output["#{key}_orig"])
        end
      else
        raise ArgumentError, "unrecognized secret type '#{type}'"
      end
    end
  end
end
