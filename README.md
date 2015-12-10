[![Build Status](https://api.travis-ci.org/alphagov/paas-cf.svg)](https://travis-ci.org/alphagov/paas-cf)

**paas-cf**

A deployment chain to provision CloudFoundry on AWS using Concoure, Terraform and BOSH

**Operation**

* A local Vagrant virtual machine is provisioned with concourse-lite.
* The deployment pipeline is pushed to concourse-lite using the concourse `fly` command.
* The deployment pipeline uses Terraform to create a VPC, subnet and security group inside AWS
* The deployment pipeline creates an RDS database instance within the VPC
* bosh-init is used to deploy a full-blown Concourse instance inside AWS
* The full-blown Concourse instance is used to deploy a Microbosh inside AWS
* The Microbosh is used to deploy CloudFoundry

**pre-requisites**

* Virtualbox
* Vagrant
* AWS Access
* 

**usage**

```
git clone https://github.com/alphagov/paas-cf.git
cd paas-cf
vagrant up
sudo curl http://192.168.100.4:8080/api/v1/cli?arch=amd64&platform=`uname | tr '[:upper:]' '[:lower:]'` -o /usr/local/bin/fly
sudo chmod +x /usr/local/bin/fly
fly login --concourse-url http://192.168.100.4:8080 sync
./concourse/scripts/deploy.sh
```



