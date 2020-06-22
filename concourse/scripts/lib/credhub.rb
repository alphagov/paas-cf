require "English"
require "json"

class CredHubClient
  attr_reader :api_url

  def initialize(api_url)
    @api_url = api_url
  end

  def certificates
    body = `credhub curl -p '#{api_url}/certificates'`
    raise body unless $CHILD_STATUS.success?
    JSON.parse(body).fetch("certificates")
  end

  def current_certificates(name)
    body = `credhub curl -p '#{api_url}/data?name=#{name}&current=true'`
    raise body unless $CHILD_STATUS.success?
    JSON.parse(body).fetch("data")
  end

  def current_certificate(name)
    current_certificates(name).first
  end

  def transitional_certificates(name)
    body = `credhub curl -p '#{api_url}/certificates?name=#{name}'`
    raise body unless $CHILD_STATUS.success?
    JSON
      .parse(body)
      .fetch("certificates").first.fetch("versions")
      .select { |c| c.fetch("transitional", false) }
  end

  def live_certificates(name)
    current = current_certificate(name)
    transitional = transitional_certificates(name)
    transitional.concat([current]).uniq { |c| c.fetch("id") }
  end

  def credential(credential_id)
    body = `credhub curl -p '#{api_url}/data/#{credential_id}'`
    raise body unless $CHILD_STATUS.success?
    JSON.parse(body)
  end

  def regenerate_certificate(cert_name)
    body = `credhub regenerate -n "#{cert_name}"`
    raise body unless $CHILD_STATUS.success?
  end

  def regenerate_certificate_as_transitional(cert_id)
    payload = { "set_as_transitional" => true }
    body = `credhub curl -p "#{api_url}/certificates/#{cert_id}/regenerate" -d '#{payload.to_json}' -X POST`
    raise body unless $CHILD_STATUS.success?
  end

  def update_certificate_transitional_version(cert_id, optional_version_id)
    payload = { "version" => optional_version_id }
    body = `credhub curl -p '#{api_url}/certificates/#{cert_id}/update_transitional_version' -d '#{payload.to_json}' -X PUT`
    raise body unless $CHILD_STATUS.success?
  end
end
