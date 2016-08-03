[![Build Status](https://api.travis-ci.org/alphagov/paas-cf.svg?branch=master)](https://travis-ci.org/alphagov/paas-cf)

# paas-cf

This repository contains [Concourse][] pipelines and related [Terraform][]
and [BOSH][] manifests that allow provisioning of [CloudFoundry][] on AWS.

[Concourse]: http://concourse.ci/
[Terraform]: https://terraform.io/
[BOSH]: https://bosh.io/
[CloudFoundry]: https://www.cloudfoundry.org/

## Overview

The following components needs to be deployed in order. They should be
destroyed in reverse order so as not to leave any orphaned resources:

1. [Bootstrap Concourse](#bootstrap-concourse)
1. [Deployer Concourse](#deployer-concourse)
1. [MicroBOSH and CloudFoundry](#microbosh-and-cloudfoundry)

The word *environment* is used herein to describe a single Cloud Foundry
installation and its supporting infrastructure.

## Bootstrap Concourse

This runs outside an environment and is responsible for creating or
destroying a [Deployer Concourse](#deployer-concourse) in an environment.
You don't need to keep this running once you have the Deployer Concourse,
and you can create it again when the Deployer Concourse needs to be modified
or destroyed.

### Prerequisites

In order to use this repository you will need:

* [AWS Command Line tool (`awscli`)](https://aws.amazon.com/cli/). You can
install it using [any of the official methods](http://docs.aws.amazon.com/cli/latest/userguide/installing.html)
or by using [`virtualenv`](https://virtualenv.pypa.io/en/latest/) and pip `pip install -r requirements.txt`

* a recent version of [Vagrant installed][]. The exact version
requirements are listed in the [`Vagrantfile`](vagrant/Vagrantfile).

[Vagrant installed]: https://docs.vagrantup.com/v2/installation/index.html

Install the AWS plugin for Vagrant:

```
vagrant plugin install vagrant-aws
```

* provide AWS access keys as environment variables:

```
export AWS_ACCESS_KEY_ID=XXXXXXXXXX
export AWS_SECRET_ACCESS_KEY=YYYYYYYYYY
```

The access keys are only required to spin up the *Bootstrap Concourse*. From
that point on they won't be required as all the pipelines will use [instance
profiles][] to make calls to AWS. The policies for these are defined in the
repo [aws-account-wide-terraform][] (not public because it also contains
state files).

[instance profiles]: http://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use_switch-role-ec2_instance-profiles.html
[aws-account-wide-terraform]: https://github.gds/government-paas/aws-account-wide-terraform

* Declare you environment name using the variable DEPLOY_ENV. It must be 18 characters maximum and contain only alphanumeric characters and hyphens.

```
$ export DEPLOY_ENV=environment-name
```

### Deploy

Create the bootstrap Concourse with `make`. Select the target based on which AWS account you want to work with. For instance for a DEV bootstrap:

```
make dev bootstrap
```
`make help` will show all available options.

NB: This will [auto-delete overnight](#overnight-deletion-of-environments)
by default.

An SSH tunnel is created so that you can access it securely. The deploy
script can be re-run to update the pipelines or set up the tunnel again.

When complete it will output a URL and BasicAuth credentials that you can
use to login.

### Destroy

Run the following script:

```
make dev bootstrap-destroy
```

## Deployer Concourse

This runs within an environment and is responsible for deploying everything
else to that environment, such as [MicroBOSH](#microbosh-and-cloudfoundry) and
[CloudFoundry](#cloudfoundry). It should be kept running while that
environment exists.

### Prerequisites

You will need a working [Bootstrap Concourse](#bootstrap-concourse).

### Deploy

Run the `create-deployer` pipeline from your *Bootstrap Concourse*.

When complete you can access the UI from a browser with the same credentials as
your *Bootstrap Concourse* on the following URL:

```
https://deployer.${DEPLOY_ENV}.dev.cloudpipeline.digital/
```

### Destroy

Run the `destroy-deployer` pipeline from your *Bootstrap Concourse*.

## MicroBOSH and Cloudfoundry

MicroBOSH is responsible for deploying [CloudFoundry](#cloudfoundry) and
supporting services for the platform.

### Prerequisites

You will need a working [Deployer Concourse](#deployer-concourse).

Deploy the pipeline configurations with `make`. Select the target based on which AWS account you want to work with. For instance, execute:
```
make dev pipelines
```
if you want to deploy to DEV account.

### Deploy

Run the `create-bosh-cloudfoundry` pipeline. This will deploy MicroBOSH, and CloudFoundry.

Run `make dev showenv` to show environment information such as system URLs and Concourse password.

This pipeline implements locking, to prevent two executions of the
same pipelines to happen at the same time. More details
in [Additional Notes](#check-and-release-pipeline-locking).

NB: The CloudFoundry deployment (but not the supporting infrastructure) will [auto-delete
overnight](#overnight-deletion-of-environments) by default.

### Destroy

Run the `destroy-cloudfoundry` pipeline to delete the CloudFoundry deployment, and supporting infrastructure.

Once CloudFoundry has been fully destroyed, run the `destroy-microbosh` pipeline to destroy MicroBOSH.

NB: If the `destroy-microbosh` pipeline is run without first cleaning up
CloudFoundry, it will be necessary to manually clean up the CloudFoundry
deployment.

# Additional notes

## Accessing CloudFoundry

To interact with a CloudFoundry environment you will need the following:

- the `cf` command line tool ([installation instructions](https://github.com/cloudfoundry/cli#downloads))
- `API_ENDPOINT` from `make dev showenv`
- `uaa_admin_password` from `cf-secrets.yml` in the state bucket

Then you can use `cf login` as [documented here](http://docs.cloudfoundry.org/cf-cli/getting-started.html#login).

You will need to supply the `--skip-ssl-validation` argument if you are
using a development environment.

## Running tests locally

You will need to install some dependencies to run the unit tests on your own
machine. The most up-to-date reference for these is the Travis CI
configuration in [`.travis.yml`](.travis.yml).

## Check and release pipeline locking

the `create-bosh-cloudfoundry` pipeline implements pipeline locking using
[the concourse pool resource](https://github.com/concourse/pool-resource).

This lock is acquired at the beginning and released the end of all the
pipeline if it finishes successfully.

In occasions it might be required to check the state or force the release
of the lock. For that you can manually trigger the jobs `pipeline-check-lock`
and `pipeline-release-lock` in the job group `Operator`.


## Optionally override the branch used by pipelines

All of the pipeline scripts (including `vagrant/deploy.sh`) honour a
`BRANCH` environment variable which allows you to override the git branch
used within the pipeline. This is useful for development and code review:

```
BRANCH=$(git rev-parse --abbrev-ref HEAD) make dev pipelines
```

## Optionally override pipeline self updating

In case you want to prevent pipelines to self update, for example because you
want to upload and test changes that you have made while developing, but not
yet pushed to the branch pipeline is currently configured to pull from, you
can use SELF_UPDATE_PIPELINE environment variable, set to false (true is default):
`SELF_UPDATE_PIPELINE=false make dev pipelines`

## Optionally deploy to a different AWS account

See [doc/non_dev_deployments.md](doc/non_dev_deployments.md).

## Optionally disable run of acceptance tests

Acceptance tests can be optionally disabled by setting the environment
variable `ENABLE_CF_ACCEPTANCE_TESTS=false`.

```
ENABLE_CF_ACCEPTANCE_TESTS=false make dev pipelines
```

It is enabled in all the environments except in `staging` and `prod`.
This will only disable the execution of the test, but the job will
be still configured in concourse.

## Optionally run specific job in the create-bosh-cloudfoundry pipeline

`create-bosh-cloudfoundry` is our main pipeline. When we are making changes or
adding new features to our deployment we many times wish to test only the
specific changes we have just made. To do that, it's many times enough to run
only the job that is applying the change. In order to do that, you can use
`run_job` makefile target. Specify the job name you want to execute by setting
the `JOB` variable. You also have to specify your environment type, e.g.
`JOB=performance-tests make dev run_job`.

This will not only tigger the job, but before that it will modify the pipeline
to remove `passed` dependencies for `paas-cf` in the specified job. This means
that your job will pick the latest changes to `paas-cf` directly, without the
need to run the pipeline from start in order to bring the changes forward.

## Sharing your Bootstrap Concourse

If you need to share access to your *Bootstrap Concourse* with a colleague
then you will need to reproduce some of the work that Vagrant does.

Add their SSH public key:

```
cd vagrant
echo "ssh-rsa AAAA... user" | \
   vagrant ssh -- tee -a .ssh/authorized_keys
```

Learn the public IP of your *Bootstrap Concourse* run:

```
cd vagrant
vagrant ssh-config
```

They will then need to manually create the SSH tunnel that is normally
handled by `vagrant/deploy.sh`:

```
ssh ubuntu@<bootstrap_concourse_ip> -L 8080:127.0.0.1:8080 -fN
```

## Using the bosh cli and `bosh ssh`

There's a Makefile target that starts an interactive session on the deployer concourse
to allow running bosh CLI commands targeting MicroBOSH:

```
make dev bosh-cli
```

You can use any environment supported by Makefile.

This connects you to a one-off task in concourse that's already logged into
bosh and has the deployment set using the CF manifest.

**Note:** `bosh ssh` no longer asks for a sudo password. By default it sets
this to blank (just press enter when asked for the sudo password within the VM)

## SSH to Deployer Concourse and MicroBOSH

In the `create-deployer` pipeline when creating the initial VPC,
a keypair is generated and uploaded to AWS to be used by deployed instances.
`bosh-init` needs this key to be able to create a SSH tunnel to
forward some ports to the agent of the new VM.

Both public and private keys are also uploaded to S3 to be consumed by
other jobs in the pipelines as resources and/or by us for troubleshooting.

To manually ssh to the *Deployer Concourse*, you will need its IP and `id_rsa` key.
You can get both from command line. You will need [aws-cli](#aws-cli), to do this:

```
eval $(make dev showenv | grep CONCOURSE_IP=)

aws s3 cp "s3://${DEPLOY_ENV}-state/id_rsa" ./deployer_id_rsa && \
chmod 400 deployer_id_rsa

ssh -i deployer_id_rsa -o IdentitiesOnly=yes -o UserKnownHostsFile=/dev/null vcap@$CONCOURSE_IP
```

If you get a "Too many authentication failures for vcap" message it is likely that you've got too many keys registered with your ssh-agent and it will fail to authenticate before trying the correct key - generally it will only allow three keys to be tried before disconnecting you. You can list all the keys registered with your ssh-agent with `ssh-add -l` and remove unwanted keys with `ssh-add -d PATH_TO_KEY`.

MicroBOSH is deployed to use the same SSH key, although is not publicly
accessible. But you can use the *Deployer Concourse* as a jumpbox:

```
ssh -o ProxyCommand="ssh -W%h:%p %r@$CONCOURSE_IP" vcap@10.0.0.6
```

## Concourse credentials

By default, the environment setup script generates the concourse ATC password
for the admin user, based on the AWS credentials, the environment name and the
application name. If the `CONCOURSE_ATC_PASSWORD` environment variable is set,
this will be used instead. These credentials are output by all of the pipeline
deployment tasks.

These credentials will also be used by the *Deployer Concourse*.

If necessary, the concourse password can be found in the `basic_auth_password`
property of `concourse-manifest.yml` in the state bucket.

You can also learn the credentials from the `atc` process arguments:

 1. SSH to the Concourse server:
    * For *Bootstrap Concourse*: `cd vagrant && vagrant ssh`
    * [For *Deployer Concourse*](#ssh-to-deployer-concourse-and-microbosh)
 2. Get the password from `atc` arguments: `ps -fea | sed -n 's/.*--basic-auth[-]password \([^ ]*\).*/\1/p'`

## Overnight deletion of environments

In order to avoid unnecessary costs in AWS, there is some logic to
stop environments and VMs at night:

 * **Bootstrap Concourse**: The `self-terminate` pipeline
   will be triggered every night to terminate the *Bootstrap Concourse*.

 * **Cloud Foundry deployment**: The `autodelete-cloudfoundry` pipeline
   will be triggered every night to delete the specific deployment.

In all cases, to prevent this from happening, you can simply pause the
pipelines or its resources or jobs.

Note that the *Deployer Concourse* and *MicroBOSH* VMs will be kept running.

## aws-cli

You might need [aws-cli][] installed on your machine to debug a deployment.
You can install it using [Homebrew][] or a [variety of other methods][]. You
should provide [access keys using environment variables][] instead of
providing them to the interactive configure command.

[aws-cli]: https://aws.amazon.com/cli/
[Homebrew]: http://brew.sh/
[variety of other methods]: http://docs.aws.amazon.com/cli/latest/userguide/installing.html
[access keys using environment variables]: http://docs.aws.amazon.com/cli/latest/userguide/cli-chap-getting-started.html#cli-environment

## Creating Users

Once you got the OK from the Product and Delivery managers to create
an organisations with a user, you can use the script `./scripts/create-user.sh`
to automatically create them:

```
./scripts/create-user.sh -o orgname -e email@example.com
```

Run `./scripts/create-user.sh` for detailed help.

The script will create the organisation if it doesnt exist, create the user and
email them the password. You must have the aws cli and cf cli installed, and be
logged into the cf environment you want to create users for

### Creating Org managers

By default, the script creates an unprivileged users. To create an org manager,
pass the `-m` option to the script.

### Verifying email address

To run the above script, you need to verify your email address with [AWS SES](https://aws.amazon.com/ses/)
To do this, run `aws ses verify-email-identity --email-address youremail@example.com --region eu-west-1`
and click on the link in the resulting email

## BOSH failover
Visit [BOSH failover page](https://github.com/alphagov/paas-cf/blob/master/doc/bosh_failover.md)

## Pingdom checks
Visit [Pingdom documentation page](https://github.com/alphagov/paas-cf/blob/master/doc/pingdom.md)
