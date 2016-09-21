# Datadog credentials

### What this is for

When setting up an environment the Datadog credentials need to be decrypted and pushed into the S3 state bucket as they are required during pipeline runs. Each environment (ci, staging, and prod) has its own set of Application and API credentials in the PaaS credential store.

### Requirements

* Make sure you have access to the PaaS credential store, this is required for Datadog credentials.
* Load the AWS credentials for the environment you are setting up datadog for. These are required as the Datadog secrets file is stored in an S3 bucket.

### Usage
```
make <ENV> upload-datadog-secrets
```

### Example for testing in a dev environment

1. Switch to a test password store dir

```
export DATADOG_PASSWORD_STORE_DIR="tmp/datadog-password-store"
```

2. Insert your test datadog keys

```
pass insert datadog/dev/datadog_api_key
pass insert datadog/dev/datadog_app_key
```

3. Upload the new keys to your state bucket

```
make dev upload-datadog-secrets
```

4. Re-run your pipelines
