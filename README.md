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
1. [MicroBOSH](#microbosh)
1. [CloudFoundry](#cloudfoundry)

The word *environment* is used herein to describe a single Cloud Foundry
installation and its supporting infrastructure.

## Bootstrap Concourse

This runs outside an environment and is responsible for creating or
destroying a [Deployer Concourse](#deployer-concourse) in an environment.
You don't need to keep this running once you have the Deployer Concourse,
and you can create it again when the Deployer Concourse needs to be modified
or destroyed.

### Prerequisites

You will need a recent version of [Vagrant installed][]. The exact version
requirements are listed in the [`Vagrantfile`](vagrant/Vagrantfile).

[Vagrant installed]: https://docs.vagrantup.com/v2/installation/index.html

Install the AWS plugin for Vagrant:

```
vagrant plugin install vagrant-aws
```

You must provide AWS access keys as environment variables:

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

### Deploy

Run the following script with the name of your environment:

```
./vagrant/deploy.sh <deploy_env>
```

NB: This will [auto-delete overnight](#overnight-deletion-of-environments)
by default.

An SSH tunnel is created so that you can access it securely. The deploy
script can be re-run to update the pipelines or set up the tunnel again.

When complete it will output a URL and BasicAuth credentials that you can
use to login.

### Destroy

Run the following script, with the name of your existing environment:

```
./vagrant/destroy.sh <deploy_env>
```

## Deployer Concourse

This runs within an environment and is responsible for deploying everything
else to that environment, such as [MicroBOSH](#microbosh) and
[CloudFoundry](#cloudfoundry). It should be kept running while that
environment exists.

### Prerequisites

You will need a working [Bootstrap Concourse](#bootstrap-concourse).

### Deploy

Run the `create-deployer` pipeline from your *Bootstrap Concourse*.

When complete you should:

1. Access the UI from a browser with the same credentials as your
  *Bootstrap Concourse*.

  - `https://deployer.${DEPLOY_ENV}.dev.paas.alphagov.co.uk/`

1. Add a new target to the `fly` CLI utility:

```
DEPLOY_ENV=<deploy-env>

$(./vagrant/environment.sh $DEPLOY_ENV) # get the credentials

echo -e "admin\n${CONCOURSE_ATC_PASSWORD}" | \
   ${FLY_CMD} -t ${DEPLOY_ENV} login -k -c "https://deployer.${DEPLOY_ENV}.dev.paas.alphagov.co.uk"
```

### Destroy

Run the `destroy-deployer` pipeline from your *Bootstrap Concourse*.

## MicroBOSH

MicroBOSH is responsible for deploying [CloudFoundry](#cloudfoundry) and
supporting services for the platform.

### Prerequisites

You will need a working [Deployer Concourse](#deployer-concourse).

Deploy the pipeline configurations with:
```
./concourse/scripts/pipelines-microbosh.sh $DEPLOY_ENV
```

### Deploy

Run the `create-microbosh` pipeline.

### Destroy

Run the `destroy-microbosh` pipeline.

## CloudFoundry

### Prerequisites

You will need a working [MicroBOSH](#microbosh).

Deploy the pipeline configurations with:
```
./concourse/scripts/pipelines-cloudfoundry.sh $DEPLOY_ENV
```

You can optionally specify a cloudfoundry RELEASE_VERSION (defaults to 225) and
STEMCELL_VERSION (defaults to 3104) as environment variables.

### Deploy

Run the `deploy-cloudfoundry` pipeline.

NB: This will [auto-delete overnight](#overnight-deletion-of-environments)
by default.

### Destroy

Run the `destroy-cloudfoundry` pipeline.

# Additional notes

## Optionally override the branch used by pipelines

All of the pipeline scripts (including `vagrant/deploy.sh`) honour a
`BRANCH` environment variable which allows you to override the git branch
used within the pipeline. This is useful for development and code review:

```
BRANCH=$(git rev-parse --abbrev-ref HEAD) <script>.sh
```

## Optionally deploy to a different AWS account

By default the scripts will deploy to the dev account. To deploy to a different
account, you'll need to export AWS access keys and secrets for the account, and
then set the `AWS_ACCOUNT` environment variable. eg to deploy/use the trial account:

```
export AWS_ACCESS_KEY_ID=your_trial_access_key
export AWS_SECRET_ACCESS_KEY=your_trial_secret_key
export AWS_ACCOUNT=trial
```

Due to the isolation between AWS accounts, when switching accounts, it's
necessary to start with a comletely new deployment.

**Note:** Different AWS accounts use different DNS names, so it'll be necessary
to adjust some of the instructions above accordingly.

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

## SSH to Deployer Concourse and MicroBOSH

In the `create-deployer` pipeline when creating the initial VPC,
a keypair is generated and uploaded to AWS to be used by deployed instances.
`bosh-init` needs this key to be able to create a SSH tunnel to
forward some ports to the agent of the new VM.

Both public and private keys are also uploaded to S3 to be consumed by
other jobs in the pipelines as resources and/or by us for troubleshooting.

To manually ssh to the *Deployer Concourse*, learn its IP via AWS console and
download the `id_rsa` file from the s3 state bucket. You will need
[aws-cli](#aws-cli), to do this:

```
aws s3 cp "s3://${DEPLOY_ENV}-state/id_rsa" . && \
chmod 400 id_rsa && \
ssh-add $(pwd)/id_rsa

ssh vcap@<deployer_concourse_ip>
```

If you get a "Too many authentication failures for vcap" message it is likely that you've got too many keys registered with your ssh-agent and it will fail to authenticate before trying the correct key - generally it will only allow three keys to be tried before disconnecting you. You can list all the keys registered with your ssh-agent with `ssh-add -l` and remove unwanted keys with `ssh-add -d PATH_TO_KEY`.

MicroBOSH is deployed to use the same SSH key, although is not publicly
accessible. But you can use the *Deployer Concourse* as a jumpbox:

```
ssh -o ProxyCommand="ssh -W%h:%p %r@<deployer_concourse_ip>" vcap@10.0.0.6
```

## Concourse credentials

`./vagrant/deploy.sh` generates the concourse ATC password for the admin user,
based on the AWS credentials, the environment name and the application name.

These credentials will also be used by the *Deployer Concourse*.

If you are the owner of the environment with the original AWS credentials,
run `./vagrant/environment.sh <deploy_env>` to get them again.

If not, you can learn the credentials from the `atc` process arguments:

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
