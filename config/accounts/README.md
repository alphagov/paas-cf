paas-accounts config
====================

[paas-accounts](https://github.com/alphagov/paas-accounts) contains a database
of documents which users need to agree to before they can use GOV.UK PaaS.

The documents directory contains documents which should be present in every
environment. The documents will be added immediately after paas-accounts is
deployed as part of the create-cloudfoundry pipeline.

Note that *any* change to a document will cause it to be create a new version,
which all users will have to agree to.

Documents are uploaded with `name` as the filename (without the .md suffix) and
`content` as the body of the file.

