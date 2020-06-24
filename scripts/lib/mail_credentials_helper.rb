require "net/http"
require "uri"
require "tempfile"

require "aws-sdk"
require "mail"

script_path = File.absolute_path(__FILE__).sub!(Dir.pwd + "/", "")
File.open(File.expand_path("~/.paas-script-usage"), "a") { |f| f.puts script_path }

module EmailCredentialsHelper
  DEFAULT_REGION = "eu-west-1".freeze

  def self.send_email(opts)
    region = opts.fetch(:region, DEFAULT_REGION)
    ses = Aws::SES::Client.new(region: region)
    mail = Mail.new do
      from    opts.fetch(:from)
      to      opts.fetch(:to)
      subject opts.fetch(:subject)

      text_part do
        body opts.fetch(:message)
      end
    end

    ses.send_raw_email(source: opts.fetch(:from),
      destinations: [opts.fetch(:to)],
      raw_message: {
        data: mail.to_s,
      })
  end

  def self.send_notification(api_url, user, source_address)
    send_email(
      from: source_address,
      to: user.fetch(:email),
      subject: "PaaS admin account creation",
      message: %(
Hello,

A CF admin user has been created for you with the following details:

 - API url: #{api_url}
 - Login: #{user.fetch(:username)}
 - Password: N/A - login is via #{user.fetch(:origin)}

You can log in by executing:

  cf login -a #{api_url} --sso

Regards,
The Government PaaS Team.

... We are building a World Class Goverment PaaS based on OpenSource... that's the best!!!
      ),
    )
  end
end
