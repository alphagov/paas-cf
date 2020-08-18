# Manage internal state under "/broker", but since this token is going to
# generate children, it needs full management of the "/cf/*" space
path "/cf/" {
  capabilities = ["list"]
}

path "/cf/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

# List all mounts
path "sys/mounts" {
  capabilities = ["read", "list"]
}

# Create mounts under the "/cf/" prefix
path "sys/mounts/cf/*" {
  capabilities = ["create", "update", "delete"]
}

# Create policies with the "cf-*" prefix
path "sys/policies/acl/cf-*" {
  capabilities = ["create", "update", "delete"]
}

# Create token role
path "/auth/token/roles/cf-*" {
  capabilities = ["create", "update", "delete"]
}

# Create tokens from role
path "/auth/token/create/cf-*" {
  capabilities = ["create", "update"]
}

# Revoke tokens by accessor
path "/auth/token/revoke-accessor" {
  capabilities = ["create", "update"]
}
