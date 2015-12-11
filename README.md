//[![Build Status](https://api.travis-ci.org/alphagov/paas-cf.svg)](https://travis-ci.org/alphagov/paas-cf)

# paas-cf

This repository contains [Concourse](http://concourse.ci/) pipelines and related [Terraform](https://terraform.io/) and [BOSH](https://bosh.io/) manifests that allow provisioning of [CloudFoundy](https://www.cloudfoundry.org/) on AWS. It consists of two chains:
- A concourse pipeline to provision CloudFoundry on AWS using Concourse, Terraform and BOSH
- A concourse pipeline to destroy previously provisioned environment.

## Operation

* A local Vagrant virtual machine is provisioned with concourse-lite.
* The deployment pipeline is pushed to concourse-lite using the concourse `fly` command.
* The deployment pipeline uses Terraform to create a VPC, subnet and security group inside AWS
* The deployment pipeline creates an RDS database instance within the VPC
* bosh-init is used to deploy a full-blown Concourse instance inside AWS
* The full-blown Concourse instance is used to deploy a Microbosh inside AWS
* The Microbosh is used to deploy CloudFoundry

## Getting started

You need the following prerequisites before you will be able to deploy first pipeline.

* Virtualbox
* Vagrant
* AWS Access

Provide AWS access keys as environment variables, plus the corresponding terraform variables.
```
export AWS_ACCESS_KEY_ID=XXXXXXXXXX
export AWS_SECRET_ACCESS_KEY=YYYYYYYYYY
export TF_VAR_AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
export TF_VAR_AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
```

## Usage

### Build

- `git clone https://github.com/alphagov/paas-cf.git`
- `cd paas-cf`
- `vagrant up`
- ```sudo curl http://192.168.100.4:8080/api/v1/cli?arch=amd64&platform=`uname | tr '[:upper:]' '[:lower:]'` -o /usr/local/bin/fly```
- `sudo chmod +x /usr/local/bin/fly`
- `fly login --concourse-url http://192.168.100.4:8080 sync`
- `./concourse/scripts/create-deployer.sh`

### Destroy
- `./concourse/scripts/destroy-deployer.sh`
