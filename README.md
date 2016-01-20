[![Build Status](https://api.travis-ci.org/alphagov/paas-cf.svg?branch=master)](https://travis-ci.org/alphagov/paas-cf)

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

The access keys are required to spin up the bootstrap concourse-lite instance only. From that point on they won't be required as all the pipelines will use [instance profiles](http://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use_switch-role-ec2_instance-profiles.html) to make calls to AWS.

#### Deployment of bootstrap concourse-lite

Execute vagrant provision script `./vagrant/deploy.sh` to initialise a vagrant
AWS instance with concourse lite.

This script will:

 * Create a running AWS concourse-lite instance with IAM role `bootstrap-concourse` (see [Vagrant bootstrap concourse-lite requirements](https://github.com/alphagov/paas-cf#vagrant-bootstrap-concourse-lite-requirements)).
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

> The concourse-lite AWS instance will be running in us-east-1, as the official
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
   fly -t $FLY_TARGET login -k -c "https://${DEPLOY_ENV}-concourse.cf.paas.alphagov.co.uk"
```

#### SSH to deployed Concourse and microbosh

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

microbosh is deployed to use the same SSH key, although is not publicly
accessible. But you can use the concourse host as a jumpbox:

```
ssh -o ProxyCommand="ssh -W%h:%p %r@<concourse_ip>" vcap@10.0.0.6
```

### Microbosh deployment from concourse bootstrap

These pipelines will deploy/destroy a microbosh using bosh-init. It will use the IAM profile `deployer-concourse` that was given to the Concourse instance.

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
./concourse/scripts/create-microbosh.sh $DEPLOY_ENV
```

This pipeline will:

 * Use terraform to create the required resources for microbosh.
 * Render `manifests/bosh-manifest` using spruce.
 * Generate a set of random passwords for bosh init.
 * Deploy microbosh using `bosh-init`


To setup the pipeline `destroy-microbosh`:

```
export FLY_TARGET=$DEPLOY_ENV
./concourse/scripts/destroy-microbosh.sh $DEPLOY_ENV
```

This pipeline will:

 * Get the resources from the deploy microbosh pipeline.
 * Run `bosh-init` to delete the deployment, updating the bosh init state
   with an empty file.
 * Destroy the resources created by terraform.

### Deploy and destroy cloudfoundry with microbosh
```
# Optionally pass the current branch for the git resources
export BRANCH=$(git rev-parse --abbrev-ref HEAD)

export FLY_TARGET=$DEPLOY_ENV
./concourse/scripts/deploy-cloudfoundry.sh $DEPLOY_ENV
```

You can optionally specify a cloudfoundry RELEASE_VERSION (defaults to 225) and
STEMCELL_VERSION (defaults to 3104) as environment variables.

This pipeline will:

 * Get VPC, microbosh and concourse state
 * use this state to run terraform and create required aws resources for cloud
   foundry
 * build the cloudfoundry manifests
 * use these manifests and microbosh instance to deploy cloudfoundry
 * Setup the cloud controller IAM role to `cf-cloudcontroller`. It must be allowed to access the S3 buckets `*-cf-resources`, `*-cf-packages`, `*-cf-droplets`, `*-cf-buildpacks`.
 * Implement a job to automatically delete the deployment overnight.

 To setup destroy pipeline you have to execute:

 ```
 ./concourse/scripts/destroy-cloudfoundry.sh <environment_name>
```

This pipeline will

 * Connect to microbosh and delete CF deployment
 * Use Terraform to destroy all the resources created by `deploy-cloudfoundry`

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
    * [For deployer concourse](#ssh-to-deployed-concourse-and-microbosh)
 2. Get the password from `atc` arguments: `ps -fea | sed -n 's/.*--basic-auth[-]password \([^ ]*\).*/\1/p'`

## Overnight deletion of environments

In order to avoid unnecessary costs in AWS, there is some logic to
stop environments and VMs at night:

 * **Terminate vagrant concourse-lite VM**: concourse-lite will have a
   pipeline `self-terminate` which will be triggered at night and
   terminate the concourse-lite vagrant instance.

 * **Delete Cloud Foundry deployment**: The `deploy-cloudfoundry` pipeline
   includes a job called `destroy` which will be triggered every night to
   delete the specific deployment.


In all cases, to prevent this from happening, you can simply pause the
pipelines or its resources or jobs.

Note that the *concourse deployer* and *microbosh* VMs will be kept running.
