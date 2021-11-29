[![Build Status](https://travis-ci.com/alphagov/paas-cf.svg?branch=master)](https://travis-ci.com/alphagov/paas-cf)

<!-- 2020-01-26[T]10:00:00  -->

# paas-cf

⚠️
When merging pull requests,
please use the [gds-cli](https://github.com/alphagov/gds-cli)
or [github_merge_sign](https://rubygems.org/gems/github_merge_sign)
⚠️

This repository contains [Concourse][] pipelines and related [Terraform][]
and [BOSH][] manifests that allow provisioning of [CloudFoundry][] on AWS.

[Concourse]: http://concourse-ci.org/
[Terraform]: https://terraform.io/
[BOSH]: https://bosh.io/
[CloudFoundry]: https://www.cloudfoundry.org/

## Overview

The following components needs to be deployed in order. They should be
destroyed in reverse order so as not to leave any orphaned resources:

1. [Deployer Concourse](#deployer-concourse)
1. [CloudFoundry](#cloudfoundry)

The word *environment* is used herein to describe a single Cloud Foundry
installation and its supporting infrastructure.

These instructions contain placeholders where the exact command may vary. The below table explains the purpose of those placeholders

| Placeholder   | Purpose                                                                                                                                                                                                           |
| ------------- | ------------------------------------------|
| `$ACCOUNT`    | The AWS account being targeted (e.g. `dev`, `staging`)|
| `$ENV` | <p>The name of the environment being targeted. In the case of short lived development environments, this should have a value of `dev`, and the specific environment is set by the `DEPLOY_ENV` environment variable (max 8 chars).</p>|


## Deployer Concourse

This runs within an environment and is responsible for deploying everything
else to that environment, such as AWS infrastructure and
[CloudFoundry](#cloudfoundry). It should be kept running while that
environment exists.

It is deployed using [paas-bootstrap]. Follow the instructions in that repo to
create a concourse instance using the `deployer-concourse` profiles etc.

[paas-bootstrap]: https://github.com/alphagov/paas-bootstrap#readme

## Cloudfoundry

The deployer concourse is responsible for deploying CloudFoundry and supporting
services for the platform.

### Prerequisites

- [ ] A working [Deployer Concourse](#deployer-concourse), which will be responsible for provisioning and deploying your infrastructure. Follow the instructions in [paas-bootstrap](https://github.com/alphagov/paas-bootstrap#readme) to create a `deployer concourse`.
- [ ] Make
- [ ] [GDS CLI](https://github.com/alphagov/gds-cli)
- [ ] Connection to the GDS VPN
- [ ] Access to paas-credentials (private repository) and tools installed. If you do not currently have access to the credentials store you may ask a team member upload the necessary credentials on your behalf.


1. Upload the necessary credentials. _If you do not currently have access to the credentials store you may ask a team member to do this step on your behalf._

   ```shell
   gds aws paas-$ACCOUNT-admin -- make $ENV upload-all-secrets
   ```

2. Deploy the pipeline configurations using `make`. This will upload/update the pipelines. Select the target based on
which AWS account you want to work with:

   ```shell
   gds aws paas-$ACCOUNT-admin -- make $ENV pipelines
   ```

### Deploy

Run the `create-cloudfoundry` pipeline. This configures and deploys CloudFoundry.
It might take a couple of hours to complete.

This pipeline implements locking, to prevent two executions of the
same pipelines from happening at the same time. More details
in [Additional Notes](#check-and-release-pipeline-locking).

NB: For personal development environments The CloudFoundry deployment (but not the supporting infrastructure) will [auto-delete
overnight](#overnight-deletion-of-environments) by default.

Run `gds aws paas-dev-admin -- make dev showenv` to show environment information such as system URLs.

Run `gds aws paas-dev-admin -- make dev credhub` to get access to the credhub credential store.

### Shared development environments
We work in shared development environments: `dev01`, `dev02` and `dev03`. They are identical to other development
environments, but they are not torn down overnight.

You can use the `make` targets to work with them; e.g.

```
gds aws paas-dev-admin -- make dev02 showenv
gds aws paas-dev-admin -- make dev02 pipelines
```

Shared environments reduce the burden on individuals running their own environments,
and prevents them from having to wait for them to start up in the morning.

### Destroy

Run the `destroy-cloudfoundry` pipeline to delete the CloudFoundry deployment, and supporting infrastructure.

# Additional notes

## Accessing CloudFoundry

To interact with a CloudFoundry environment you will need the following:

- the `cf` command line tool ([installation instructions](https://github.com/cloudfoundry/cli#downloads))
- The API endpoint from `gds aws paas-$ACCOUNT-admin -- make $ENV showenv`.

Login using `cf login --sso` as [documented here](https://docs.cloud.service.gov.uk/get_started.html#use-single-sign-on)

Alternatively, you can use `cf login` as [documented here](http://docs.cloudfoundry.org/cf-cli/getting-started.html#login), 
to log in as the `admin` user, using the `cf_admin_password` from `gds aws paas-$ACCOUNT-admin -- make $ENV credhub`.

## Running tests locally

You will need to install some dependencies to run the unit tests on your own
machine. The most up-to-date reference for these is the Travis CI
configuration in [`.travis.yml`](.travis.yml).

## Check and release pipeline locking

the `create-cloudfoundry` pipeline implements pipeline locking using
[the concourse pool resource](https://github.com/concourse/pool-resource).

This lock is acquired at the beginning and released the end of all the
pipeline if it finishes successfully.

To check the state or force the release
of the lock, you can manually trigger the jobs `pipeline-check-lock`
and `pipeline-release-lock` in the job group `Operator`.

## Optional flags
### Override the branch used by pipelines

All the pipeline scripts honour a
`BRANCH` environment variable which allows you to override the git branch
used within the pipeline. This is useful for development and code review:

```
BRANCH=$(git rev-parse --abbrev-ref HEAD) make dev pipelines
```

Alternatively, you can use the `current-branch` option:
```shell
gds aws paas-dev-admin -- make dev02 current-branch pipelines
```

### Override pipeline self updating
The pipelines are configured watch a specific branch and self-update when changes
are pushed.

You can prevent this from happening by setting `SELF_UPDATE_PIPELINE=false` (it is true by default):

```
gds aws paas-dev-admin -- SELF_UPDATE_PIPELINE=false make dev pipelines
```

This can be useful when you want to upload and test changes that you have made while developing, but not
yet pushed to the branch pipeline is currently configured to pull from

###  Disable run of acceptance tests

Acceptance tests can be optionally disabled by setting the environment
variable `DISABLE_CF_ACCEPTANCE_TESTS=true`. This is default in staging and prod.

```
DISABLE_CF_ACCEPTANCE_TESTS=true SELF_UPDATE_PIPELINE=false make dev pipelines
```

This will only disable the execution of the test, but the job will
be still configured in concourse.

*Note:* `SELF_UPDATE_PIPELINE` is also disabled because enabling it would result in the first run immediately enabling the acceptance tests again.

### Disable run of custom acceptance tests

Custom acceptance tests can be optionally disabled by setting the environment
variable `DISABLE_CUSTOM_ACCEPTANCE_TESTS=true`.

```
DISABLE_CUSTOM_ACCEPTANCE_TESTS=true SELF_UPDATE_PIPELINE=false make dev pipelines
```

This will only disable the execution of the test, but the job will be still configured in concourse.

*Note:* `SELF_UPDATE_PIPELINE` is also disabled because enabling it would result in the first run reverting to default, which is to run the tests.

###  Disable pipeline locking

Pipeline locking is turned on by default to prevent jobs in the pipeline run while previous changes are still being applied. You can optionally
disable this by setting the environment variable `DISABLE_PIPELINE_LOCKING=true`. This is default in dev to speed up pipeline execution.

```
DISABLE_PIPELINE_LOCKING=true SELF_UPDATE_PIPELINE=false make dev pipelines
```

Self update pipeline has to be disabled, otherwise it would revert to default value in the pipeline and unlock job would fail since pipeline was not locked before it self updated.

### Run specific job in the create-cloudfoundry pipeline

`create-cloudfoundry` is our main pipeline. When we are making changes or
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

##  Deploy to a different AWS account

See [doc/non_dev_deployments.md](doc/non_dev_deployments.md).

## Concourse credentials

When run from your laptop, the environment setup script does not interact with
Concourse using long-lived credentials. If you need to get persistent Concourse
credentials please use `make <env> credhub`.

## Overnight deletion of environments

In order to avoid unnecessary costs in AWS, there is some logic to
stop environments and VMs at night:

 * **Cloud Foundry deployment**: The `autodelete-cloudfoundry` pipeline
   will be triggered every night to delete the specific deployment.

In all cases, to prevent this from happening, you can simply pause the
pipelines or its resources or jobs.

Note that the *Deployer Concourse* and *MicroBOSH* VMs will be kept running.

## Morning kick-off of deployment

The pipeline `deployment-kick-off` can trigger for you the deployment in
the morning, so the environment is ready for you before you start work.

This feature is opt-in and must be enable **every day** by unpausing the
`deployment-timer` resource in `deployment-kick-off`, either manually or
by running:

```
make dev unpause-kick-off
```

The `deployment-timer` would be disabled automatically just after the
deployment is kick-off, to prevent the next day to happen again. You can
avoid this by pausing the job `pause-kick-off`

## aws-cli

You might need [aws-cli][] installed on your machine to debug a deployment.
You can install it using [Homebrew][] or a [variety of other methods][]. You
should provide [access keys using environment variables][] instead of
providing them to the interactive configure command.

[aws-cli]: https://aws.amazon.com/cli/
[Homebrew]: http://brew.sh/
[variety of other methods]: http://docs.aws.amazon.com/cli/latest/userguide/installing.html
[access keys using environment variables]: http://docs.aws.amazon.com/cli/latest/userguide/cli-chap-getting-started.html#cli-environment


## Pingdom checks
Visit [Pingdom documentation page](https://github.com/alphagov/paas-cf/blob/master/doc/pingdom.md)

## Other useful commands
Type `make` to get the list of all available commands.
