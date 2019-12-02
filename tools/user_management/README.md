# `paas-cf/tools/user_management`

This folder contains a User Management tool for controlling which users have global permissions on the PaaS. For instance it enforces who has `cloud_controller.admin` or `cloud_controller.global_auditor`. We're starting to run this as part of our pipelines.

## Configuration

Provide the path to a YAML file with content like the following:

```
---
- email: EMAIL_ADDRESS_GOES_HERE
  google_id: GOOGLE_NUMERIC_ACCOUNT_ID_GOES_HERE
  cf_admin: OPTIONAL_BOOLEAN_WHICH_DEFAULTS_TO_FALSE_IF_NOT_PROVIDED

- […]
```

Without `cf_admin: true` a user will be given Global Auditor permissions only.

## How to run manually

See the way this is invoked by our pipelines and copy that.

## Features

* The script will complain if any members of the UAA Groups listed in `main.rb` don't match up with the users config provided;
* The script will remove unexpected users from the UAA Groups if the user was created more than 1 hour ago (this allows for temporary admin-level smoke test users);
* The script will not remove a user from the groups if its `userName` is `admin` and it is using the `uaa` origin, but it also will not add it to the groups;
* The script will create new UAA users if the configured users don't already exist. They are all configured to sign in with Google;
* The script will add those desired users to the UAA Groups configured based upon the `cf_admin` boolean. If they aren't a `cf_admin` they will only get Global Auditor permissions.

### Why this is great to have

On each run this script will sync who has privileged, global access to the PaaS against our config file. It'll output any unexpected group members, and remove them if they've existed for more than an hour.
