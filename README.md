[![Build Status](https://api.travis-ci.org/alphagov/paas-cf.svg)](https://travis-ci.org/alphagov/paas-cf)

# paas-cf

This repository contains [Concourse](http://concourse.ci/) pipelines and
related [Terraform](https://terraform.io/) and [BOSH](https://bosh.io/) manifests
that allow provisioning of [CloudFoundy](https://www.cloudfoundry.org/) on AWS.

## Getting started

You need the following prerequisites before you will be able to deploy first pipeline.

* Virtualbox
* Vagrant
* AWS Access

Provide AWS access keys as environment variables.
```
export AWS_ACCESS_KEY_ID=XXXXXXXXXX
export AWS_SECRET_ACCESS_KEY=YYYYYYYYYY
```

## Usage

### Prepare the local environment

1. Clone repo and boot the vagrant node with concourse:

    ```
git clone https://github.com/alphagov/paas-cf.git
cd paas-cf
vagrant up
```

2. Install your `fly` binary:

    ```
FLY_CMD_URL="http://192.168.100.4:8080/api/v1/cli?arch=amd64&platform=$(uname | tr '[:upper:]' '[:lower:]')"
sudo curl $FLY_CMD_URL -o /usr/local/bin/fly && \
sudo chmod +x /usr/local/bin/fly
```

3. Login on the local vagrant concourse:

     ```
fly login --target vagrant --concourse-url http://192.168.100.4:8080 sync
```

### Deploy the deployer concourse

```
export FLY_TARGET=vagrant
CONCOURSE_ATC_PASSWORD=atcpassword CONCOURSE_DB_PASSWORD=dbpassword ./concourse/scripts/create-deployer.sh env_name
```

* CONCOURSE_DB_PASSWORD is the RDS database password. It must be 8 characters long minimum
* CONCOURSE_ATC_PASSWORD is the deployed Concourse web interface password

Also, you can specify log level and branch by setting LOG_LEVEL and BRANCH variables.

```
export FLY_TARGET=vagrant
BRANCH=branch_name LOG_LEVEL=DEBUG CONCOURSE_ATC_PASSWORD=atcpassword CONCOURSE_DB_PASSWORD=dbpassword ./concourse/scripts/create-deployer.sh env_name
```

This script will:

- Use a local Vagrant virtual machine with concourse-lite.
- Use Terraform to create a VPC, subnet and security group inside AWS
- bosh-init is used to deploy a full-blown Concourse instance inside AWS

### Login to deployed Concourse

* Point the browser to http://"environment"-concourse.cf.paas.alphagov.co.uk:8080/
* Login with username admin and password as CONCOURSE_ATC_PASSWORD above

### Destroy the deployer concourse

```
export FLY_TARGET=vagrant
./concourse/scripts/destroy-deployer.sh env_name
```

or

```
export FLY_TARGET=vagrant
LOG_LEVEL=DEBUG BRANCH=branch_name ./concourse/scripts/destroy-deployer.sh env_name

export FLY_TARGET=vagrant
./concourse/scripts/destroy-deployer.sh
```

Will destroy the resources created in the previous run.

### Login on the remote concourse

In order to use the concourse, you must add and login to the new target:

```
export DEPLOY_ENV=<deploy-env> # change me
export CONCOURSE_ATC_PASSWORD=atcpassword # change me

export FLY_TARGET=$DEPLOY_ENV

echo -e "admin\n${CONCOURSE_ATC_PASSWORD}" | \
   fly -t $FLY_TARGET login -c http://${DEPLOY_ENV}-concourse.cf.paas.alphagov.co.uk:8080

fly -t $FLY_TARGET sync
```
### Microbosh deployment

These pipelines will deploy/destroy a microbosh using bosh-init.

> Note about AWS credentials: These pipelines can receive the variables
> `AWS_ACCESS_KEY_ID` or `AWS_SECRET_ACCESS_KEY` for terraform and `bosh-init`.
> If not provided, it will use IAM profiles.

#### Deploy a microbosh with bosh-init from concourse

Requires run first the deployer pipeline, to provide:
 * A VPC setup and bucket for the state files.
 * A running concourse configured in the CLI

To execute it:

```
# Optionally pass the current branch for the git resources
export BRANCH=$(git rev-parse --abbrev-ref HEAD)

export FLY_TARGET=$DEPLOY_ENV
./concourse/scripts/create-microbosh.sh <environment_name>
```

This pipeline will:

 * Use terraform to create the required resources for microbosh.
 * Render `manifests/bosh-manifest` using spruce.
 * Generate a set of random passwords for bosh init.
 * Deploy microbosh using `bosh-init`


#### Destroy microbosh with bosh-init

```
# Optionally pass the current branch for the git resources
export BRANCH=$(git rev-parse --abbrev-ref HEAD)

export FLY_TARGET=$DEPLOY_ENV
./concourse/scripts/destroy-microbosh.sh <environment_name>
```

This pipeline will:

 * Get the resources from the deploy microbosh pipeline
 * Run bosh-init to delete the deployment, updating the bosh init state
   with an empty file.
 * Destroy the resources created by terraform.
