require 'uri'

RSpec.describe "release versions" do
  matcher :match_version_from_url do |url|
    match do |version|
      if url =~ %r{\?v=(.+)\z}
        url_version = $1
      elsif url =~ %r{-([\d.]+)\.tgz\z}
        url_version = $1
      else
        raise "Failed to extract version from URL '#{url}'"
      end
      version == url_version
    end
  end

  specify "release versions match their download URL version" do
    manifest_with_defaults.fetch("releases").each do |release|
      expect(release.fetch('version')).to match_version_from_url(release.fetch('url')),
        "expected release #{release['name']} version #{release['version']} to have matching version in URL: #{release['url']}"
    end
  end
end
