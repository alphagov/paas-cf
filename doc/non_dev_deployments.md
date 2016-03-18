# Non-dev deployments

Deploying to a non-dev account follows largely the same process as dev
deployments. There are a few details that are different though:

## Access Keys

To deploy to a different account, you'll need to export AWS access keys
and secrets for the account. eg to deploy/use the CI account:

```
export AWS_ACCESS_KEY_ID=your_ci_access_key
export AWS_SECRET_ACCESS_KEY=your_ci_secret_key
```

## DNS names

The [README](../README.md) instructions contain domain names for the dev
deployments. For other deployments these will be different. For example, the
deployer concourse in a ci environment has the URL
`https://deployer.${DEPLOY_ENV}.ci.cloudpipeline.digital/`, and in production
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
should use "production".

## Deployment process

With the above in mind, the deployment process is the same as for a dev
deployment, except that you need to use the appropriate env target when running
make tasks (eg for production use `make prod bootstrap`)

Once the deployer-concourse has been created, the bootstrap-concourse should be
destroyed.

## Recording credentials etc.

Once deployed, concourse password should be recorded in the credentials store
so that other team members can access the environment. This should be done in a
way that makes it clear what the `DEPLOY_ENV` is for the deployment.
