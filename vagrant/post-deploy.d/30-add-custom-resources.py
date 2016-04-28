#!/usr/bin/env python
import json
import subprocess

config_file = '/var/vcap/jobs/groundcrew/config/worker.json'

with open(config_file,'r') as f:
    config = json.load(f)

    config["resource_types"].extend([
        { "type": "s3-iam", "image": "docker:///governmentpaas/s3-resource" },
        { "type": "semver-iam", "image": "docker:///governmentpaas/semver-resource" },
        { "type": "git-gpg", "image": "docker:///governmentpaas/git-resource" }
    ])

    # Remove any duplicates hashing by type. via http://stackoverflow.com/a/11092590
    config["resource_types"] = {v['type']:v for v in config["resource_types"]}.values()

with open(config_file,'w') as f:
    json.dump(config, f)

subprocess.check_call(["/var/vcap/bosh/bin/monit", "restart", "beacon"])

