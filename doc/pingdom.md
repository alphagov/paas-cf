# Pingdom checks

## Setting up the checks

The checks are defined in terraform configuration file `terraform/pingdom/pingdom.tf`.

The IDs of the contacts to be notified are stored as a comma-delimited string in variable `$PINGDOM_CONTACT_IDS` in the Makefile.

### Requirements

* [Terraform](https://www.terraform.io/downloads.html) must be installed. See the Makefile for the minimum Terraform version.
* Make sure you have access to the PaaS credential store, this is required for Pingdom credentials.
* Load the AWS credentials for the environment you are setting up checks for. These are required as the Terraform state file for the Pingdom checks is stored in an S3 bucket.

### Usage
To review changes:
```
make <ENV> pingdom ACTION=plan
```

To apply changes:
```
make <ENV> pingdom ACTION=apply
```

## Build from source

#### Requirements
You must have a [golang environment](https://golang.org/doc/install) configured. We currently test with Go 1.6.
 
#### Download
Download the provider and its dependencies:

```
go get github.com/russellcardullo/terraform-provider-pingdom
```

#### Custom provider
For bleeding-edge features, it may be necessary to build the provider from our fork.

```
# go-pingdom library
cd $GOPATH/src/github.com/russellcardullo/go-pingdom
git remote add alphagov git@github.com:alphagov/paas-go-pingdom.git
git fetch alphagov
git checkout gds_master

# terraform-provider-pingdom
cd $GOPATH/src/github.com/russellcardullo/terraform-provider-pingdom
git remote add alphagov git@github.com:alphagov/paas-terraform-provider-pingdom.git
git fetch alphagov
git checkout gds_master
```

#### Terraform version
You may need to ensure your Terraform version is compatible with the terraform library used to compile the provider.
You can run `terraform -v` to get your version of Terraform and find the corresponding git tag for this version in `$GOPATH/src/github.com/hashicorp/terraform`.
Use the tag to checkout that version of the terraform library prior to installing the provider.

```
cd $GOPATH/src/github.com/hashicorp/terraform
git fetch
git tag -l
git checkout v0.6.15
```

#### Install
Run `go install github.com/russellcardullo/terraform-provider-pingdom`. This will build and install the binary in `$GOPATH/bin`. Make sure `$GOPATH/bin` is in your `$PATH`.

Terraform will look in various places to find plugin binaries, see the [discover](https://github.com/hashicorp/terraform/blob/10cc8b8c63f0e780c022c2e9b25e954bf7a7bca8/config.go#L80) function.

For temporary work, it should be sufficient create a symlink of the same name in the directory from which you will run `terraform`.

## Publishing the custom provider
Build from inside directory `$GOPATH/src/github.com/russellcardullo/terraform-provider-pingdom`.

### Build for Linux

```
GOOS=linux GOARCH=amd64 go build -v -o terraform-provider-pingdom-Linux-x86_64
```

### Build for MacOS
```
GOOS=darwin GOARCH=amd64 go build -v -o terraform-provider-pingdom-Darwin-x86_64
```

### Publish
The binary is published as a release in our [paas-terraform-provider-pingdom repository](https://github.com/alphagov/paas-terraform-provider-pingdom/releases). When code is merged into the `gds_master` branch, tag the merge commit and upload the binaries as a GitHub release.
