# paas-cf

⚠️
When merging pull requests, use the [gds-cli](https://github.com/alphagov/gds-cli): `gds git merge-sign alphagov/paas-cf PR_NUMBER`
⚠️

GOV.UK Platform as a Service (PaaS) CF creates a deployment of [Cloud Foundry](https://www.cloudfoundry.org/) (CF) on VMs for GOV.UK PaaS. It builds upon the foundations laid out in [`paas-bootstrap`](https://github.com/alphagov/paas-bootstrap) and it handles the following non-exhaustive list of duties:

+ [Deploying CF using Concourse](https://github.com/alphagov/paas-cf/blob/main/concourse/pipelines/create-cloudfoundry.yml)
+ [Configuring CF](https://github.com/alphagov/paas-cf/tree/main/manifests/cf-manifest) based on [`cf-deployment`](https://github.com/cloudfoundry/cf-deployment)
+ [Provisioning AWS resources using Terraform](https://github.com/alphagov/paas-cf/tree/main/terraform/cloudfoundry). This includes
   + load balancers
   + databases
   + IAM roles and policies
   + DNS records
   + networking
   + S3 buckets
+ [Configuring Prometheus](https://github.com/alphagov/paas-cf/tree/main/manifests/prometheus) based on [`prometheus-boshrelease`](https://github.com/bosh-prometheus/prometheus-boshrelease)
+ Running continuous [platform-level tests](https://github.com/alphagov/paas-cf/tree/main/platform-tests)
+ Deploying and configuring our different service brokers (for example, the [RDS broker](https://github.com/alphagov/paas-cf/blob/main/manifests/cf-manifest/operations.d/710-rds-broker.yml) and [Aiven broker](https://github.com/alphagov/paas-cf/blob/main/manifests/cf-manifest/operations.d/741-aiven-broker.yml))

It does not include the AWS IAM roles which are assumed by different system components. Those are created in the account wide terraform (private repository).

## Contents
1. [What does `paas-cf` contain?](#what-does-paas-cf-contain)
1. [Deploying a new environment](#deploying-a-new-environment)
1. [Cloud Foundry deployment configuration options](#cloud-foundry-deployment-configuration-options)
1. [Accessing Concourse](#accessing-concourse)
1. [Finding configuration](#finding-configuration)

## What does `paas-cf` contain?
`paas-cf` separates the responsibility for configuring, deploying, running, and monitoring Cloud Foundry, from those responsibilities held by [`paas-bootstrap`](https://github.com/alphagov/paas-bootstrap).

This repository does not itself contain the code that runs in an environment (for the most part), but instead serves to compose the different pieces into a cohesive whole. As a result, it contains a variety of pieces that tell only part of the story. The table under the heading [Finding configuration](#Finding-configuration) outlines some key directories and their purposes.

## Deploying a new environment
At a very high level, the [`create-cloudfoundry` Concourse pipeline](https://github.com/alphagov/paas-cf/blob/main/concourse/pipelines/create-cloudfoundry.yml) generates a [Bosh manifest](https://bosh.io/docs/manifest-v2/) which describes the virtual machines and their networking which make up the Cloud Foundry deployment, as well as the software which runs on each machine. The manifest is then [submitted](https://github.com/alphagov/paas-cf/blob/main/concourse/pipelines/create-cloudfoundry.yml#L2899) to the Bosh director configured in `paas-bootstrap`.

### Pre-requisites
Before you can get a Cloud Foundry deployment up and running, you will need the following available

+ [ ] A running [`deployer-concourse` instance from `paas-bootstrap`](https://github.com/alphagov/paas-bootstrap)
+ [ ] Make
+ [ ] Ruby >= 2.7
+ [ ] [GDS CLI](https://github.com/alphagov/gds-cli)
+ [ ] Access to `paas-credentials` (private repository) and tools installed
+ [ ] Connection to GDS VPN
+ [ ] Permission to assume the `Admin` role of the relevant AWS account (dev, ci, staging, production)
+ [ ] `AWS_DEFAULT_REGION` environment set the desired region for the environment
+ [ ] [cf CLI](https://docs.cloudfoundry.org/cf-cli/install-go-cli.html) >=7

### Deploy Cloud Foundry

These instructions contain placeholders where the exact command may vary. The below table explains the purpose of those placeholders:

| Placeholder   | Purpose                                                                                                                                                                                                           |
| ------------- | ------------------------------------------|
| `$ACCOUNT`    | The AWS account being targeted (for example, `dev`, `staging`)|
| `$ENV` | The name of the environment being targeted. In the case of short lived development environments, this should have a value of `dev`, and the specific environment is set by the `DEPLOY_ENV` environment variable (max 8 chars)|

1. Log in to [CredHub](https://docs.cloudfoundry.org/credhub/) in the environment by running this and following the instructions on screen. This will take you into a new shell session.
   ```shell
   gds aws paas-$ACCOUNT-admin -- make $ENV credhub
   ```

1. Upload the secrets to CredHub from the CredHub shell session.
   ```shell
   make $ENV upload-all-secrets
   ```

   Note: you do not need to use GDS CLI here because the CredHub shell session contains the AWS credentials in environment variables

1. Exit the CredHub shell session

1. Deploy the pipeline configurations using `make`. This will upload or update the pipelines. Select the target based on which AWS account you want to work with:

   ```shell
   gds aws paas-$ACCOUNT-admin -- make $ENV pipelines
   ```
1. Log in to Concourse. See the [Accessing Concourse](#accessing-concourse).

1. Tun the `generate-paas-admin-git-keys`, `generate-paas-billing-git-keys` and `generate-paas-aiven-broker-git-keys` jobs in the job group `operator`. This will generate and store some SSH keys needed by other jobs.

1. Run the `create-cloudfoundry` pipeline, starting from the left-hand `pipeline-lock` job. This will configure and deploy Cloud Foundry. It might take a couple of hours to complete.

## Cloud Foundry deployment configuration options

There are a handful of configuration options which can change a Cloud Foundry deployment which can only be set at pipeline level. Each of the properties in the below table should be set as [Make variables](https://www.gnu.org/software/make/manual/make.html#Environment) when setting the pipelines:

```
gds aws paas-$ACCOUNT-admin -- make $ENV pipelines VAR=value
```

| Property (VAR) | Type | Default | Description |
| -- | -- | -- | -- |
| `BRANCH` | String | `main` | Sets the `paas-cf` branch which will be used in the pipeline |
| `DEPLOY_ENV` | String | `null` for short-lived dev envs, fixed in `Makefile` for other envs | Sets the name of the environment |
| `SELF_UPDATE_PIPELINE` | Bool | `true` | Whether the pipeline should update its own definition from the current branch at runtime. Disable this if you're making a pipeline change which has not been pushed to branch yet |
| `SLIM_DEV_DEPLOYMET` | Bool| `true` in dev, `false` elsewhere | If `true`, reduces the number and size of VMs created for each component to 2. In dev, set this to `false` when testing the impact of a change on platform availability |
|`DISABLED_AZS` | String list, space separated | `""` | <p>Disables the given availability zones in Bosh. This is used when an availability zone goes away, and we need to redistribute virtual machines away from that AZ. </p><p> Set to a value like `"z1 z2"`</p>|
|`ENABLE_AUTODELETE` | Bool | `true` in dev, `false` elsewhere | <p>If `true`, deploys a pipeline which tears down Cloud Foundry at 8pm each day as a cost saving measure.</p><p>This should absolutely never be set to `true` in a staging or production deployment</p> |
|`ENABLE_DESTROY` | Bool | `true` in dev, `false` elsewhere |<p>If `true`, deploys a pipeline which, when run, will completely destroy Cloud Foundry and all of its data</p><p>This should absolutely never be set to `true` in a staging or production deployment</p>|

## Accessing Concourse
Once deployed, Concourse can be accessed from the URLs below. By default, authentication with Github is enabled.

| Environment type | Environment name | URL |
| ---------------- | ---------------- | --- |
| Dev | Unique name | https://deployer.$NAME.dev.cloudpipeline.digital/ |
| Dev | Dev[0-9]+ | https://deployer.dev$NUMBER.dev.cloudpipeline.digital/ |
| Staging | `stg-lon` | https://deployer.london.staging.cloudpipeline.digital/ |
| CI | `build` | https://concourse.build.ci.cloudpipeline.digital/ |
| Production | `prod` | https://deployer.cloud.service.gov.uk/ |
| Production | `prod-lon` | https://deployer.london.cloud.service.gov.uk/ |

Non-development URLs are also accessible via the `gds paas open` command.

## Finding configuration
The following table outlines some important directories in the repository, their purpose, and when you might need to look in them.

| Directory | Purpose | I will need this when .. |
| -- | -- | -- |
| `concourse/pipelines/` | YAML definitions of the Concourse pipelines | I want to make a change to how the platform is deployed, monitored, or torn down |
| `config/billing/` | The scripts and static files used to generate configuration for the billing system.| <ul><li>I'm adding a new backing service, so that I can set how much it costs.</li><li>The VAT rate has changed </li><li>The cost of an AWS resource has changed</li></ul>|
| `manifests/cf-manifest/` | The Bosh manifest configuration for Cloud Foundry | See specific directories below |
| `manifests/cf-manifest/operations.d/` | Customisations applied to `cf-deployment`, applicable to all environments | <ul><li>I want to make a configuration change that will affect every environment</li><li>I want to deploy a new piece of software with a Bosh release</li></ul>
| `manifests/cf-manifest/operations` | Customisations applied to `cf-deployment` [based on some condition](https://github.com/alphagov/paas-cf/blob/main/manifests/cf-manifest/scripts/generate-manifest.sh#L18) | I want to make a configuration change that will only be applied in certain circumstances |
|`manifests/cf-manifest/spec`| Unit tests applied to the generated manifest file | I want to make sure a property of the manifest is not invalidated (for example, correct number of instances of some VM) |
|`manifests/cf-manifest/env-specific`| Values of variables per environment | I want to change things like the number of Diego cells deployed in an environment |
| `terraform/az-monitoring` | Terraform configuration for out availability zone monitoring solution | I want to make a change to how we monitoring how alive an availability zone is |
| `terraform/cloudfoundry` | Terraform configuration for the AWS resources associated with running Cloud Foundry | <ul><li>I want to set/unset DNS records</li><li>I want to configure ingress for a new service broker</li><li>I want to alter Cloud Foundry's AWS network architecture</li></ul>|
| `terraform/spec` | Unit tests applied to Terraform configuration | I want to make an assertion about Terraform configuration as part of the unit tests
| `terraform/vpc-peering` | Terraform configuration for VPC peering between the Cloud Foundry VPC and others | I want to change a property of our existing VPC peers, and future ones |
| `tools/buildpacks` | Golang implementation of our regular buildpack update emails | I want to make a change to the email we send to tenants about buildpack updates |
| `tools/metrics` | A Prometheus exporter which exposes a variety of platform-level metrics collected from different sources | <ul><li>I want to add a new metrics</li><li>I want to change the frequency of the measurement of an existing metric</li></ul>|
