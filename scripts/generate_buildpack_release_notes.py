#!/usr/bin/env python3

import os
import re
import sys
import yaml
import argparse
import requests
from git import Repo

script_path = sys.argv[0]
description = """----------------------------------------------------------------
DESCRIPTION: Generates the aggregate summary of changes of all the buildpacks between two versions of the CF release.

 - summary.md: list of versions and links to the release notes
 - detailed.md: all the changes with the content of the release notes

This tool handles updates to buildpacks, and new buildpacks. It may not correctly handle renamed or removed buildpacks.

To use it, you must first clone the cf-release repo and check out its new release:
    
    git clone http://github.com/cloudfoundry/cf-release.git ../cf-release
    cd ../cf-release
    git checkout <version_to>
    ./scripts/update

You can override the path by setting the `--cf-release-dir` argument.

You may encounter rate limiting errors with the Github API. To avoid this you will need to get a read token from github in

 - https://github.com/settings/tokens

Finally run the program passing the versions to check:

    %s <version_from> <version_to>

Example:

    %s v264 v269

or:

    %s v264 v269 --cf-release-dir ~/workspace/cf-release/ --github-user=keymon --github-api-token=1234567891234567890
----------------------------------------------------------------
""" % (script_path, script_path, script_path)

parser = argparse.ArgumentParser(description=description, formatter_class=argparse.RawTextHelpFormatter)
parser.add_argument('version_from')
parser.add_argument('version_to')
parser.add_argument('--github-user', nargs='?', help='Github username.')
parser.add_argument('--github-api-token', nargs='?', help='Github API token with permission to read public repos.')
parser.add_argument('--release-notes-dir', default="/tmp/buildpack_release_notes", help='Destination path for the buildpack release notes.')
parser.add_argument('--cf-release-dir', default=os.path.dirname(sys.argv[0]) + "/../cf-release", help='Path to a cf-release directory with all submodules checked out.')

args = parser.parse_args()

print("Trying to generate buildpack release changenotes from cf-release", args.version_from, "to", args.version_to)

repo = Repo(args.cf_release_dir)
assert not repo.bare

rev_a = repo.tags[args.version_from]
rev_b = repo.tags[args.version_to]

if not os.path.isdir(args.release_notes_dir):
	os.mkdir(args.release_notes_dir)
summary_file_path = args.release_notes_dir + "/summary_file.md"
detailed_file_path = args.release_notes_dir + "/detailed_file.md"
summary_file = open(summary_file_path, "w+")
detailed_file = open(detailed_file_path, "w+")

print("# Buildpack updates summary", file=summary_file)
print("# Buildpack updates detailed", file=detailed_file)

# @TODO FIXME: You need to identify removed buildpack-releases. If you diff the tree
# you might be able to see them? You'll need to check. It'd be best to output such 
# messages at the top of the output files.
for dirname in os.listdir("cf-release/src/"):
	print("")
	dirpath = "cf-release/src/%s" % dirname
	print("Examining directory '%s' with path '%s'" % (dirname, dirpath))

	if not dirname.endswith("-buildpack-release") or not os.path.isdir(dirpath):
		print("  Skipping because not a buildpack-release directory.")
		continue
	print("  It's a buildpack-release directory")
	assert dirname[-8:] == "-release"

	buildpack_name = dirname[:-8]
	print("  For the '%s' buildpack" % buildpack_name)

	if buildpack_name == "dotnet-core-buildpack":
		print("  Skipping .NET buildpack.")
		continue
	elif "offline" in buildpack_name:
		print("  Skipping offline buildpack '%s'" % buildpack_name)
		continue

	# Diff the path to this buildpack-release, to get its old and new commit hash.
	buildpack_submodule_diff = rev_a.commit.diff(rev_b.commit, "src/%s" % dirname)
	if len(buildpack_submodule_diff) == 0:
		print("  Skipping because the buildpack inside the release was not updated.")
		continue
	elif len(buildpack_submodule_diff) > 1:
		unreachable()
	buildpack_submodule_diff = buildpack_submodule_diff[0]
	buildpack_submodule_old_commit_hash = buildpack_submodule_diff.a_blob
	buildpack_submodule_new_commit_hash = buildpack_submodule_diff.b_blob
	print("  The buildpack submodule commit changed")
	print("    From:", buildpack_submodule_old_commit_hash)
	print("    To:  ", buildpack_submodule_new_commit_hash)

	buildpack_repo = Repo(dirpath)
	assert not buildpack_repo.bare

	# Parse the `releases/___/index.yml` file for the old and new commit of this buildpack-release.
	# If the buildpack is new then treat all versions as new.
	if buildpack_submodule_old_commit_hash is None:
		print("  This seems to be a new buildpack")
		buildpack_submodule_old_release_index = {"builds": {}}
	else:
		buildpack_submodule_old_commit = buildpack_repo.commit(buildpack_submodule_old_commit_hash)
		buildpack_submodule_old_release_index_yaml = buildpack_submodule_old_commit.tree["releases/%s/index.yml" % buildpack_name].data_stream.read()
		buildpack_submodule_old_release_index = yaml.load(buildpack_submodule_old_release_index_yaml)
	buildpack_submodule_new_commit = buildpack_repo.commit(buildpack_submodule_new_commit_hash)
	buildpack_submodule_new_release_index_yaml = buildpack_submodule_new_commit.tree["releases/%s/index.yml" % buildpack_name].data_stream.read()
	buildpack_submodule_new_release_index = yaml.load(buildpack_submodule_new_release_index_yaml)

	versions = []
	# Identify releases of the buildpack that are new since the old commit.
	for new_uuid in buildpack_submodule_new_release_index["builds"]:
		if new_uuid not in buildpack_submodule_old_release_index["builds"]:
			version = buildpack_submodule_new_release_index["builds"][new_uuid]["version"]
			print("  There has been a new version of the buildpack")
			print("    Version named", version)
			print("    Version UUID", new_uuid)
			versions.append(version)

	# Print the summary.
	print("\n##", buildpack_name, file=summary_file)
	print("New versions: ", ", ".join(versions), "\n", file=summary_file)
	for version in versions:
		print(" * https://github.com/cloudfoundry/%s/releases/tag/%s" % (buildpack_name, version), file=summary_file)

	# Print the detailed summary. We get the release notes from Github.
	print("\n##", buildpack_name, file=detailed_file)
	print("New versions: ", ", ".join(versions), "\n", file=detailed_file)
	for version in versions:
		print("###", buildpack_name, version, "\n", file=detailed_file)

		print("  Requesting changelog for version", version, "from Github.")
		r = requests.get("https://api.github.com/repos/cloudfoundry/%s/releases/tags/v%s" % (buildpack_name, version), auth=(args.github_user, args.github_api_token))
		assert r.status_code == 200
		buildpack_version_release_notes = r.json()["body"]
		# For readability we prepend markdown quotes ('> ') to each line of the buildpack version's release notes.
		quoted_buildpack_version_release_notes = re.sub("^", "> ", buildpack_version_release_notes, flags=re.MULTILINE)

		print(quoted_buildpack_version_release_notes, file=detailed_file)
		print("", file=detailed_file)

	print("  Done.")

print("\nCOMPLETE!")
print("  See summary output at", summary_file_path)
print("  See detailed output at", detailed_file_path)

print("\nWARNING ABOUT COMPLETENESS:")
print("  REMOVED OR RENAMED BUILDPACKS WILL NOT BE DETECTED.")
print("  PLEASE MANUALLY CHECK FOR THESE AND ADD ANY RELEVANT RELEASE NOTES.")

