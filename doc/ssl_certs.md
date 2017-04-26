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

 1. Once the deployer concourse has been created, execute the make task
    `manually_upload_certs` to upload the certs to the AWS. You indicate the
    [password store](https://www.passwordstore.org/) directory to read the
    certificates from by passing the variable `CERT_PASSWORD_STORE_DIR`

    To review changes: `make <ENV> manually_upload_certs CERT_PASSWORD_STORE_DIR=/path/to/credentials-high ACTION=plan`

    To apply changes: `make <ENV> manually_upload_certs CERT_PASSWORD_STORE_DIR=/path/to/credentials-high ACTION=apply`

 1. Continue with the standard procedure to deploy cloudfoundry.

### Rotating the certs for an existing deployment

 1. Update the certs in the cred store

 1. Run the `manually_upload_certs` make task:

    `make <ENV> manually_upload_certs CERT_PASSWORD_STORE_DIR=/path/to/credentials-high ACTION=apply`

    This will run, upload the new certs, and then eventually fail (after c. 3
    mins) when attempting to delete the old certs. This is expected because
    they're still in use.

 1. Run the deployment pipeline, which will update the system to use the new
    certs.

 1. Run the `setup_cdn_instances` make task if applicable (typically only
    applicable in production) to update the docs and product pages CDN certs.

 1. Clean up the old certs by running `manually_upload_certs` again:

    `make <ENV> manually_upload_certs CERT_PASSWORD_STORE_DIR=/path/to/credentials-high ACTION=apply`

    You should see the deposed resources being destroyed successfully.
