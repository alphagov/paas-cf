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

  specify "manifest versions are not older than the ones in cf_deployment" do
    def normalise_version(v)
      Gem::Version.new(v.gsub(/^v/, '').gsub(/^([0-9]+)$/, '0.0.\1'))
    end

    manifest_releases = manifest_with_defaults.fetch("releases").map { |release|
      [release['name'], release['version']]
    }.to_h

    cf_deployment_manifest.fetch("releases").each do |release|
      next if release['name'].end_with? '-buildpack'

      if manifest_releases.has_key? release['name']
        cf_deployment_release_version = release.fetch('version')
        manifest_release_version = manifest_releases[release['name']]

        expect(normalise_version(manifest_release_version)).to be >= normalise_version(cf_deployment_release_version),
          "expected #{release['name']} release version #{manifest_release_version} not to be older than #{cf_deployment_release_version} as defined in cf-deployment"
      end
    end
  end
end
