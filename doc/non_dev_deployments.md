# Non-dev deployments

Deploying to a non-dev account follows largely the same process as dev
deployments. There are a few details that are different though:

## Access Keys

To deploy to a different account, you'll need to export AWS access keys
and secrets for the account. eg to deploy/use the staging account:

```
export AWS_ACCESS_KEY_ID=your_staging_access_key
export AWS_SECRET_ACCESS_KEY=your_staging_secret_key
```

## DNS names

The [README](../README.md) instructions contain domain names for the dev
deployments. For other deployments these will be different. For example, the
deployer concourse in the staging environment has the URL
`https://deployer.london.staging.cloudpipeline.digital/`, and in production
has the URL `https://deployer.cloud.service.gov.uk/`

The deployment scripts will output the URLs of the targets they're operating
on. Alternatively the domains can be found in the env-specific targets in the
[`Makefile`](../Makefile).

## Deployment environment name

All deployments require that `DEPLOY_ENV` is set. This has to be unique across
all deployments and accounts (it's used to create the state bucket name, and S3
bucket names have to be gloablly unique)

For staging and production a `DEPLOY_ENV` is required even though it's not used
in domain names. Staging should use a `DEPLOY_ENV` of "staging", and production
should use "prod".

## Deployment process

With the above in mind, the deployment process is the same as for a dev
deployment, except that you need to use the appropriate env target when running
make tasks (eg for production use `make prod bootstrap`)

Once the deployer-concourse has been created, the bootstrap-concourse should be
destroyed.

### Environments that create tags in git.

Some deployments create release tags in git (eg the staging deployment). These
therefore need write access to the git repo.  This is done as follows:

* Run the `generate-git-keys` job on the deployer concourse (found in the
  `release` group of the `create-cloudfoundry` pipeline)
* Grab the generated ssh public key from the output of that job.
* Add this as a [deploy key](https://developer.github.com/guides/managing-deploy-keys/#deploy-keys)
  to the repo - this needs to be done by civil servant. Set the title to the FQDN of the
  deployer concourse, and give it write access.

## Recording credentials etc.

Once deployed, concourse password should be recorded in the credentials store
so that other team members can access the environment. This should be done in a
way that makes it clear what the `DEPLOY_ENV` is for the deployment.

## Accessing an existing deployment

In order to operate on an existing deployment that was created with a different
AWS key to your own, it's necessary to export the concourse password:
```
export CONCOURSE_ATC_PASSWORD=the_password
```

## Destroying an existing environment

The pipelines to destroy Cloud Foundry and MicroBOSH are not setup
automatically on non-development environments in order to prevent accidental
deletion. They can be setup if you do need them by running:
```
ENABLE_DESTROY=true make <env> pipelines
```
