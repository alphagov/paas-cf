## Cloud Foundry manifests.

These have been taken from the upstream [cf-release
repository](https://github.com/cloudfoundry/cf-release), and adapted to use
spruce.

The intention is that these will be developed with a focus on ease of
understanding and maintainability, instead of keeping in sync with upstream.
This means that we are editing these files rather than adding additional layers
in spruce.

### Dependencies

This requires [spruce](https://github.com/geofffranks/spruce#readme) (commit
`6b89bc7` or later). If you have a working Go installation, this can be
installed/updated with:

    go get -u github.com/geofffranks/spruce
