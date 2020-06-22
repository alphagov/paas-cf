require "uri"

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
      expect(release.fetch("version")).to match_version_from_url(release.fetch("url")),
        "expected release #{release['name']} version #{release['version']} to have matching version in URL: #{release['url']}"
    end
  end

  specify "manifest versions are not older than the ones in cf_deployment" do
    def normalise_version(v)
      Gem::Version.new(v.gsub(/^v/, "").gsub(/^([0-9]+)$/, '0.0.\1'))
    end

    pinned_releases = {
      "uaa" => {
        local: "0.1.23",
        upstream: "74.18.0",
      }
    }

    manifest_releases = manifest_without_vars_store.fetch("releases").map { |release|
      [release["name"], release["version"]]
    }.to_h

    cf_deployment_releases = cf_deployment_manifest.fetch("releases").map { |release|
      [release["name"], release["version"]]
    }.to_h

    unpinned_cf_deployment_releases = cf_deployment_releases.reject { |name, _version|
      pinned_releases.has_key? name
    }.to_h

    unpinned_cf_deployment_releases.each { |name, version|
      next if name.end_with? "-buildpack"
      next unless manifest_releases.has_key? name
      expect(normalise_version(manifest_releases[name])).to be >= normalise_version(version),
        "expected #{name} release version #{manifest_releases[name]} to be older than #{version} as defined in cf-deployment. Maybe you need to pin it?"
    }

    pinned_releases.each { |name, pinned_versions|
      expect(manifest_releases).to have_key(name), "expected pinned release #{name} for found in manifest"
      expect(cf_deployment_releases).to have_key(name), "expected pinned release #{name} for found in cf-deployment"
      expect(normalise_version(manifest_releases[name])).to be(normalise_version(pinned_versions[:local])),
         "expected #{name} to be using our own built tarball #{pinned_versions[:local]} not #{manifest_releases[name]}"

      expect(normalise_version(cf_deployment_releases[name])).to be(normalise_version(pinned_versions[:upstream])),
        "expected #{name} upstream to be #{pinned_versions[:upstream]} not #{cf_deployment_releases[name]}. We might need to rebase our forked #{name} release and generate a new tarball, or use the upstream version."
    }
  end

  specify "cf-smoke-tests-release version is not older than in upstream" do
    cf_smoke_tests_release = cf_deployment_manifest
      .fetch("releases")
      .select { |v| v["name"] == "cf-smoke-tests" }
      .fetch(0)

    cf_smoke_tests_resource = cf_pipeline
      .fetch("resources")
      .select { |v| v["name"] == "cf-smoke-tests-release" }
      .fetch(0)

    upstream_version = Gem::Version.new(cf_smoke_tests_release["version"])
    paas_version = Gem::Version.new(cf_smoke_tests_resource["source"]["tag_filter"])

    expect(paas_version).to be >= upstream_version, "we should upgrade the cf-smoke-tests-release's tag_filter in the create-cloundfoundry pipeline to #{upstream_version} or greater"
  end

  specify "create-cloudfoundry cf-smoke-tests-release version to match monitor-remote" do
    cf_smoke_tests_resource_version = cf_pipeline
      .fetch("resources")
      .select { |v| v["name"] == "cf-smoke-tests-release" }
      .fetch(0)
      .fetch("source")
      .fetch("tag_filter")

    monitor_remote_smoke_tests_resource_version = monitor_remote_pipeline
      .fetch("resources")
      .select { |v| v["name"] == "cf-smoke-tests-release" }
      .fetch(0)
      .fetch("source")
      .fetch("tag_filter")

    expect(monitor_remote_smoke_tests_resource_version).to eq(cf_smoke_tests_resource_version)
  end

  specify "cf-acceptance-tests version should be the same as the CF manifest version" do
    cf_manifest_version = cf_deployment_manifest
      .fetch("manifest_version")

    cf_acceptance_tests_resource = cf_pipeline
      .fetch("resources")
      .select { |v| v["name"] == "cf-acceptance-tests" }
      .fetch(0)

    upstream_version = Gem::Version.new(cf_manifest_version.gsub(/^v/, "").gsub(/\.0$/, ""))

    if cf_acceptance_tests_resource["source"]["branch"] == "master"
      expect(upstream_version).to be == Gem::Version.new("11.0"), "there was no release of github.com/cloudfoundry/cf-acceptance-tests for cf-deployment v11.0. remove this erroring line and uncomment the below if they fix this for v12"
    else
      paas_version = Gem::Version.new(cf_acceptance_tests_resource["source"]["branch"].gsub(/^cf/, ""))
      expect(paas_version).to be >= upstream_version, "we should upgrade the cf-acceptance-tests' branch in the create-cloundfoundry pipeline to 'cf#{upstream_version}'"
    end
  end

  specify "releases do not include buildpacks" do
    manifest_without_vars_store.fetch("releases").each do |release|
      expect(release.fetch("name")).not_to end_with("-buildpack")
    end
  end
end
