require 'net/http'
require 'uri'
require 'tempfile'

require 'aws-sdk'
require 'mail'
require 'gpgme'

module EmailCredentialsHelper

  DEFAULT_SOURCE_ADDRESS = "the-multi-cloud-paas-team@digital.cabinet-office.gov.uk"
  DEFAULT_REGION = "eu-west-1"

  def self.encrypt_message_to(message, key)
    uri = URI.parse("http://pgp.mit.edu/pks/lookup?op=get&options=mr&search=0x" + key)
    response = Net::HTTP.get_response(uri)
    if response.code != "200"
      raise "Cannot find GPG key #{key} in pgp.mit.edu"
    end

    Dir.mktmpdir("gpg-mail") do |tmpdir|
      GPGME::Engine.home_dir = tmpdir
      GPGME::Key.import(response.body)
      GPGME::Crypto.encrypt(message, :recipients => key, :always_trust => true)
    end
  end

  def self.send_email(opts)
    region = opts.fetch(:region, DEFAULT_REGION)
    ses = Aws::SES::Client.new(:region => region)
    mail = Mail.new do
      from    opts[:source_address]
      to      opts[:email]
      subject opts[:subject]

      text_part do
        body opts[:message]
      end
    end
    opts[:attachments].each { | name, value |
      mail.attachments[name] = value
    }

    ses.send_raw_email({
      source: opts[:from],
      destinations: [opts[:to]],
      raw_message: {
        data: mail.to_s,
      },
    })
  end

  def self.send_admin_credentials(api_url, user, source_address=nil)
    source_address ||= DEFAULT_SOURCE_ADDRESS

    attachment_source = encrypt_message_to(user[:password], user[:gpg_key])

    send_email(
      :from           => source_address,
      :to             => user[:email],
      :subject        => "PaaS admin account credentials",
      :message        => %Q{
Hello,

A CF admin user has been created for you with the following details:

 - API url: #{api_url}
 - Login: #{user[:username]}
 - Password: Attached as a GPG encrypted file with key ID #{user[:gpg_key]}

You can decrypt the password attachment using:

  gpg -d paas_admin_password.gpg

You can login and change your password by executing:

  cf login -a #{api_url} -u #{user[:username]}
  cf passwd

Regards,
The Government PaaS Team.

... We are building a World Class Goverment PaaS based on OpenSource... that's the best!!!
      },
      :attachments    =>  {
        'paas_admin_password.gpg' => {
          :mime_type => "text/PGP; charset=binary",
          :content   => attachment_source.to_s
        }
      }
    )
  end
end
