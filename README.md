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

The access keys are required to spin up the bootstrap concourse-lite instance only. From that point on they won't be required as all the pipelines will use [instance profiles](http://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use_switch-role-ec2_instance-profiles.html) to make calls to AWS.

### Deploy

Run the following script with the name of your environment:

```
./vagrant/deploy.sh <deploy_env>
```

An SSH tunnel is created so that you can access it securely. The deploy
script can be re-run to update the pipelines or setup the tunnel again.

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

  - `https://${DEPLOY_ENV}-concourse.cf.paas.alphagov.co.uk/`

1. Add a new target to the `fly` CLI utility:

```
DEPLOY_ENV=<deploy-env>

$(./vagrant/environment.sh $DEPLOY_ENV) # get the credentials

echo -e "admin\n${CONCOURSE_ATC_PASSWORD}" | \
   ${FLY_CMD} -t ${DEPLOY_ENV} login -k -c "https://${DEPLOY_ENV}-concourse.cf.paas.alphagov.co.uk"
```

### Destroy

Run the `destroy-deployer` pipeline from your *Bootstrap Concourse*.

## MicroBOSH

MicroBOSH is responsible for deploying [CloudFoundry](#cloudfoundry) and
supporting services for the platform.

### Prerequisites

You will need a working [Deployer Concourse](#deployer-concourse).

### Deploy

To setup the pipeline `create-microbosh`:

```
./concourse/scripts/create-microbosh.sh $DEPLOY_ENV
```

### Destroy

To setup the pipeline `destroy-microbosh`:

```
./concourse/scripts/destroy-microbosh.sh $DEPLOY_ENV
```

## CloudFoundry

### Prerequisites

You will need a working [MicroBOSH](#microbosh).

### Deploy

```
./concourse/scripts/deploy-cloudfoundry.sh $DEPLOY_ENV
```

You can optionally specify a cloudfoundry RELEASE_VERSION (defaults to 225) and
STEMCELL_VERSION (defaults to 3104) as environment variables.

An additional pipeline `autodelete-cloudfoundry` is setup to automatically
delete the environment at night.

### Destroy

To setup destroy pipeline you have to execute:

 ```
 ./concourse/scripts/destroy-cloudfoundry.sh <environment_name>
```

# Additional notes

## SSH tunnel to vagrant concourse-lite and share access to instance

Instead of allowing a non secure HTTP connection via the internet to the
concourse-lite AWS instance, we create a SSH tunnel to redirect the port
8080 to localhost.

After running vagrant/deploy.sh "daemonized" SSH redirection will be
running listening in the port localhost:8080.

If the machine needs to be shared with a coworker, and additional SSH
public key can be added with:

```
cd vagrant
echo "ssh-rsa AAAA... user" | \
   vagrant ssh -- tee -a .ssh/authorized_keys
```

A new tunnel can be created manually running:

```
ssh ubuntu@<remote concourse ip> -L 8080:127.0.0.1:8080 -fN
```

To learn the public IP of the created concourse, simply run:

```
cd vagrant
vagrant ssh-config
```

## Optionally override the branch used by pipelines

The pipeline setup script will accept a variable `BRANCH`, which allows
override the working branch for development and review:

```
# Optionally pass the current branch for the git resources
export BRANCH=$(git rev-parse --abbrev-ref HEAD)
```

## SSH to deployed Concourse and microbosh

In the `create-deployer` pipeline when creating the initial VPC,
a keypair is generated and uploaded to AWS to be used by deployed instances.
`bosh-init` needs this key to be able to create a SSH tunnel to
forward some ports to the agent of the new VM.

Both public and private keys are also uploaded to S3 to be consumed by
other jobs in the pipelines as resources and/or by us for troubleshooting.

To manually ssh to the deployed concourse, learn its IP via AWS console and
download the `id_rsa` file from the s3 state bucket.

For example:

```
./concourse/scripts/s3get.sh "${DEPLOY_ENV}-state" id_rsa && \
chmod 400 id_rsa && \
ssh-add $(pwd)/id_rsa

ssh vcap@<concourse_ip>
```

If you get a "Too many authentication failures for vcap" message it is likely that you've got too many keys registered with your ssh-agent and it will fail to authenticate before trying the correct key - generally it will only allow three keys to be tried before disconnecting you. You can list all the keys registered with your ssh-agent with `ssh-add -l` and remove unwanted keys with `ssh-add -d PATH_TO_KEY`.

microbosh is deployed to use the same SSH key, although is not publicly
accessible. But you can use the concourse host as a jumpbox:

```
ssh -o ProxyCommand="ssh -W%h:%p %r@<concourse_ip>" vcap@10.0.0.6
```

## Concourse credentials

`./vagrant/deploy.sh` generates the concourse ATC password for the admin user,
based on the AWS credentials, the environment name and the application name.

These credentials will be used in the final concourse installation (deployer).

If you are the owner of the environment with the original AWS credentials,
run `./vagrant/environment.sh <deploy_name>` to get them again.

If not, you can learn the credentials from the `atc` process arguments:

 1. Login on the concourse server:
    * For vagrant bootstrap concourse-lite: `cd vagrant && vagrant ssh`
    * [For deployer concourse](#ssh-to-deployed-concourse-and-microbosh)
 2. Get the password from `atc` arguments: `ps -fea | sed -n 's/.*--basic-auth[-]password \([^ ]*\).*/\1/p'`

## Overnight deletion of environments

In order to avoid unnecessary costs in AWS, there is some logic to
stop environments and VMs at night:

 * **Terminate vagrant concourse-lite VM**: concourse-lite will have a
   pipeline `self-terminate` which will be triggered at night and
   terminate the concourse-lite vagrant instance.

 * **Delete Cloud Foundry deployment**: The `autodelete-cloudfoundry` pipeline
   will be triggered every night to delete the specific deployment.

In all cases, to prevent this from happening, you can simply pause the
pipelines or its resources or jobs.

Note that the *concourse deployer* and *microbosh* VMs will be kept running.
