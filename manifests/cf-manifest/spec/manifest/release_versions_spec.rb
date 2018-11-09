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
    manifest_without_vars_store.fetch("releases").each do |release|
      expect(release.fetch('version')).to match_version_from_url(release.fetch('url')),
        "expected release #{release['name']} version #{release['version']} to have matching version in URL: #{release['url']}"
    end
  end

  specify "manifest versions are not older than the ones in cf_deployment" do
    def normalise_version(v)
      Gem::Version.new(v.gsub(/^v/, '').gsub(/^([0-9]+)$/, '0.0.\1'))
    end

    manifest_releases = manifest_without_vars_store.fetch("releases").map { |release|
      [release['name'], release['version']]
    }.to_h

    cf_deployment_manifest.fetch("releases").each do |release|
      next if release['name'].end_with? '-buildpack'

      if manifest_releases.has_key? release['name']
        cf_deployment_release_version = release.fetch('version')
        manifest_release_version = manifest_releases[release['name']]


        # Special case for capi-release. See commit message
        if release['name'] == 'capi'
          custom_capi_release_version = normalise_version('0.1.1')
          expect(normalise_version(manifest_release_version)).to be(custom_capi_release_version),
            "expected #{release['name']} to be using our own built tarball #{custom_capi_release_version} not #{manifest_release_version}"

          expected_upstream_capi_release_version = normalise_version('1.71.0')
          expect(normalise_version(cf_deployment_release_version)).to be(expected_upstream_capi_release_version),
            "expected #{release['name']} upstream to be #{expected_upstream_capi_release_version} not #{cf_deployment_release_version}. We might need to rebase our forked capi-release repo and generate a new tarball"
          next
        end

        expect(normalise_version(manifest_release_version)).to be >= normalise_version(cf_deployment_release_version),
          "expected #{release['name']} release version #{manifest_release_version} not to be older than #{cf_deployment_release_version} as defined in cf-deployment"
      end
    end
  end
end
