[![Build Status](https://api.travis-ci.org/alphagov/paas-cf.svg)](https://travis-ci.org/alphagov/paas-cf)

# paas-cf

This repository contains [Concourse](http://concourse.ci/) pipelines and
related [Terraform](https://terraform.io/) and [BOSH](https://bosh.io/) manifests
that allow provisioning of [CloudFoundy](https://www.cloudfoundry.org/) on AWS.


## Getting started

You need the following prerequisites before you will be able to deploy first pipeline.

* [Vagrant](https://www.vagrantup.com/)
* [AWS Vagrant plugin](https://github.com/mitchellh/vagrant-aws)
* AWS Access and credentials

## Usage

### Concourse deployer bootstrap

#### Installing vagrant and plugins

To install vagrant follow the instructions [in vagrant documentation](https://docs.vagrantup.com/v2/installation/index.html).

Once installed, install the vagrant AWS plugin with:

```
vagrant plugin install vagrant-aws
```

#### AWS credentials

You must provide AWS access keys as environment variables.

```
export AWS_ACCESS_KEY_ID=XXXXXXXXXX
export AWS_SECRET_ACCESS_KEY=YYYYYYYYYY
```

#### SSH credentials

You must have insecure-deployer private key present in `~/.ssh/insecure-deployer` location, 
as it is being used by pipeline creation scripts.

#### Deployment of bootstrap concourse-lite

Execute vagrant provision script `./vagrant/deploy.sh` to initialise a vagrant
AWS instance with concourse lite.

This script will:

 * Create a running AWS concourse-lite instance.
 * Do additional post configuration of concourse, like add basic authentication
   to concourse lite and mount garden container storage to instance ephemeral disk.
 * Configure a SSH tunnel to redirect the remote concourse port 8080 to http://localhost:8080
 * Download the `fly` command from concourse-lite in the current directory.
 * Login and create a new fly target called `<deploy-env>-bootstrap`.
 * Upload the `create-deployer` and `destroy-deployer` pipelines.

After run, you will get:

 * Concourse URL to connect to, which will be http://localhost:8080
 * Concourse credentials.

To execute it:

```
./vagrant/deploy.sh <deploy_env>
```

> The concourse-lite AWS instance will be running in us-west-1, as the official
> concourse-lite AMI image is only located there.
>
> The instance has some default hardcoded settings: security groups, VPC,
> IAM role. See below for more details.


#### Pipelines: create-deployer and destroy-deployer

These pipelines run on the bootstrap concourse-lite and will deploy the
concourse instance (deployer) for the environment.

Both pipelines are setup automatically by `./vagrant/deploy.sh`

The `create-deployer` pipeline will:

- Use terraform to create a VPC, subnet and security group inside AWS.
- Use terraform to setup all the requirements for concourse.
- bosh-init is used to deploy a full-blown Concourse instance inside AWS.

The `destroy-deployer` pipeline will destroy the previous created objects.

#### Login to deployed Concourse

Once the `create-deployer` pipeline finished successful, you can:

* Point the browser to `https://${DEPLOY_ENV}-concourse.cf.paas.alphagov.co.uk/`
* Login with username `admin` and password as `$CONCOURSE_ATC_PASSWORD` above

You can add a new target in to use the `fly` command with:

```
DEPLOY_ENV=<deploy-env>

$(./vagrant/environment.sh $DEPLOY_ENV) # get the credentials

export FLY_TARGET=$DEPLOY_ENV

echo -e "admin\n${CONCOURSE_ATC_PASSWORD}" | \
   fly -t $FLY_TARGET login -k -c https://${DEPLOY_ENV}-concourse.cf.paas.alphagov.co.uk
```

#### ssh to deployed Concourse

During the deploy process, a keypair is created in aws to create the instance
with. This is uploaded to s3 and then discarded, to avoid the private key being
left anywhere in the pipeline. To ssh to the instance, find its ip in the
console and download the deployer-key file from the s3 state bucket, then run

```
ssh -i <deployer-key-file-from-state-bucket> vcap@${DEPLOY_ENV}-concourse.cf.paas.alphagov.co.uk
```

### Microbosh deployment from concourse bootstrap

These pipelines will deploy/destroy a microbosh using bosh-init.

> Note about AWS credentials: These pipelines can receive the variables
> `AWS_ACCESS_KEY_ID` or `AWS_SECRET_ACCESS_KEY` for terraform and `bosh-init`.
> If not provided, it will use IAM profiles.

#### Prerequisites

To run the following steps you must have these prerequisites:

 * The `create-deployer` pipeline has been run from a bootstrap concourse.
 * A VPC is setup and there is a bucket for the state files.
 * The `fly` command is installed and available
 * A running concourse configured in the CLI, with target name `$DEPLOY_ENV`

#### Pipelines: create-microbosh and destroy-microbosh

To setup the pipeline `create-microbosh`:

```
export FLY_TARGET=$DEPLOY_ENV
./concourse/scripts/create-microbosh.sh <environment_name>
```

This pipeline will:

 * Use terraform to create the required resources for microbosh.
 * Render `manifests/bosh-manifest` using spruce.
 * Generate a set of random passwords for bosh init.
 * Deploy microbosh using `bosh-init`


To setup the pipeline `destroy-microbosh`:

```
export FLY_TARGET=$DEPLOY_ENV
./concourse/scripts/destroy-microbosh.sh <environment_name>
```

This pipeline will:

 * Get the resources from the deploy microbosh pipeline.
 * Run `bosh-init` to delete the deployment, updating the bosh init state
   with an empty file.
 * Destroy the resources created by terraform.

# Additional notes

## Vagrant bootstrap concourse-lite requirements

In order to use vagrant concourse-lite on AWS, there are requirements
on the AWS account:

* Existence of a default VPC and subnet.
* A default security group, which restricts access to the office only
  to port 22 (ssh).
* A IAM role to be assigned to the VM, which allows:
  * Provision EC2 resources to setup the initial VPC and concourse.
  * Access to S3 buckets for state storage (usually named `*-state`)

All these objects are currently hardcoded in `vagrant/Vagrantfile`

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

## Concourse credentials

`./vagrant/deploy.sh` generates the concourse ATC password for the admin user,
based on the AWS credentials, the environment name and the application name.

These credentials will be used in the final concourse installation (deployer).

If you are the owner of the environment with the original AWS credentials,
run `./vagrant/environment.sh <deploy_name>` to get them again.

If not, you can learn the credentials from the `atc` process arguments:

 1. Login on the concourse server:
    * For vagrant bootstrap concourse-lite: `cd vagrant && vagrant ssh`
    * For deployer concourse: `ssh -l vcap ${DEPLOY_ENV}-concourse.cf.paas.alphagov.co.uk`
 2. Get the password from `atc` arguments: `ps -fea | sed -n 's/.*--basic-auth[-]password \([^ ]*\).*/\1/p'`

