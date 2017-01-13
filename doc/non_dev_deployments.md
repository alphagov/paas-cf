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
should use "prod".

## Obtaining new SSL certificates

We use digicert for our SSL certificates. The credentials for this are stored in
the high creds store - this is a global account but with these credentials you
should create your own account under Account - Users. You should only do this if
you have access to the high creds store, and do not create accounts for users
without access to this.

Once you have this account, and access to a suitable payment method, you can
order a new SSL certificate by going to "Request a Certificate". The certificate
type needed is a "Wildcard Plus" certificate.


## Rotating SSL certificates in digicert

To rotate an existing certificate, go to Certificates - Orders. Then click on
the order with the Common Name you want to rotate. You must then use the
"Request Duplicate" functionality rather than "reissue cert" as the former
allows you to include SANs.

## Certificate options in digicert

Both renewing and requesting a certificate require the following options to be
set

Common name (CN) is the wildcard app or system domain
Other Hostnames (SANs) is the app or system domain name without the wildcard.
For example, for the production app domain cloudapps.digital, the CN would be
`*.cloudapps.digital` and the SAN would be `cloudapps.digital`.

For signature hash, we use sha-256, and the server platform should be apache

## Creating a CSR

For both obtaining certificates for a new environment, and rotating certificates
you will need to generate a CSR. For consistency, we do this using a docker
container so we can be sure of which versions of software we used to
generate the certificate. This is important in case there are future
vulnerabilities in the software used to create the keys so we can decide if our
keys were affected by these.

Use the following command to generate a certificate

```
docker run --rm -t -i -v `pwd`/staging:/certs governmentpaas/certstrap \
            certstrap --depot-path /certs \
            request-cert \
            --passphrase '' \
            --country GB \
            --organization 'Government Digital Service' \
            --common-name '*.example.com'
```

replacing example.com with the required common name

In the commit message for the certificates in the high cred store, you should
include the command used to generate the certificate.

You should also include the full output of this command 

`docker inspect governmentpaas/certstrap`

in the commit message. This includes important information such as the go
version and version of the container we used to create the certificates. You can
see an example of a commit message following this format in the high creds store
git history

## Domains in digicert

If digicert gives you an error when requesting a certificate, you may need to
deactivate and then activate the domain. This can be done by clicking on
domains, then clicking on the domain for the cert, and then clicking deactivate.
Once this is done you should be able to click activate again. This was found
after putting in a support ticket with digicert.


## Manual upload of SSL certificates

For some environments (e.g. prod) we want to use purchased valid certificates
for the public facing endpoints, instead of using self signed certificates. In
that case, the operator must manually upload the certificates:

The certificates and the intermediate CA cert need to be stored in the
[credentials-high][] password store, using this naming convention:

 * `certs/${AWS_ACCOUNT}/${DEPLOY_ENV}/${CERT_NAME}.crt`
 * `certs/${AWS_ACCOUNT}/${DEPLOY_ENV}/${CERT_NAME}.key`
 * `certs/${AWS_ACCOUNT}/${DEPLOY_ENV}/${CERT_NAME}_intermediate.crt`

Currently the process requires a `system_domain` and `apps_domain` cert.

[credentials-high]: https://github.gds/government-paas/credentials-high

### Initial deployment of an environment

 1. After deploying the deployer with `create-deployer`, execute the make task
    `manually_upload_certs`. You indicate the
    [password store](https://www.passwordstore.org/) directory to read
    the certificates from by passing the variable `CERT_PASSWORD_STORE_DIR`

    To review changes: `make <ENV> manually_upload_certs CERT_PASSWORD_STORE_DIR=~/.paas-pass ACTION=plan`

    To apply changes: `make <ENV> manually_upload_certs CERT_PASSWORD_STORE_DIR=~/.paas-pass ACTION=apply`

 1. Continue with the standard procedure to deploy cloudfoundry.

### Rotating the certs for an existing deployment

 1. List the server certificates, and make a note of their
    `ServerCertificateName`. This will be needed to clean up afterwards.

    `aws iam list-server-certificates`

 1. Update the certs in the cred store

 1. Run the `manually_upload_certs` make task:

    `make <ENV> manually_upload_certs CERT_PASSWORD_STORE_DIR=~/.paas-pass ACTION=apply`

    This will run, upload the new certs, and then eventually fail (after c. 3
    mins) when attempting to delete the old certs. This is expected because
    they're still in use.

 1. Run the deployment pipeline, which will update the system to use the new
    certs.

 1. Clean up the old certs using the names noted down in step 1.

    `aws iam delete-server-certificate --server-certificate-name staging-apps-domain-123456....`
    `aws iam delete-server-certificate --server-certificate-name staging-system-domain-123456....`

## Deployment process

With the above in mind, the deployment process is the same as for a dev
deployment, except that you need to use the appropriate env target when running
make tasks (eg for production use `make prod bootstrap`)

Once the deployer-concourse has been created, the bootstrap-concourse should be
destroyed.

### Environments that create tags in git.

Some deployments create release tags in git (eg the ci master deployment, and
the staging deployment). These therefore need write access to the git repo.
This is done as follows:

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
