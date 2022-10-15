//////////////////////////////////
// Mount kv2 engine
//////////////////////////////////

resource "vault_mount" "KV2" {
  path        = "kv2"
  description = "KV Secret Engine (v2) mount"
  type        = "kv"
  
  options     = {
    version = "2"
  }
}

//////////////////////////////////
// Vault | Policies
//////////////////////////////////

resource "vault_policy" "TERRAFORM" {
  name = "tf-operator-policy"

  policy = <<-POLICY
  path "auth/token/lookup-accessor" {
    capabilities = ["update"]
  }

  path "auth/token/revoke-accessor" {
    capabilities = ["update"]
  }
  POLICY
}

resource "vault_policy" "EXAMPLE" {
  name = "example-policy"

  policy = <<-POLICY
  # Lookup own properties
  path "auth/token/lookup-self" {
    capabilities = ["read"]
  }

  # Renew themselves
  path "auth/token/renew-self" {
    capabilities = ["update"]
  }

  # Revoke themselves
  path "auth/token/revoke-self" {
    capabilities = ["update"]
  }

  # Lookup own capabilities on a path
  path "sys/capabilities-self" {
    capabilities = ["update"]
  }

  path "sys/internal/ui/resultant-acl" {
    capabilities = ["read"]
  }
  POLICY
}

//////////////////////////////////
// Vault | Roles
//////////////////////////////////

resource "vault_token_auth_backend_role" "EXAMPLE" {
  role_name              = "example-role"
  allowed_policies       = ["example-policy"]
  disallowed_policies    = ["default"]
  allowed_entity_aliases = []
  orphan                 = true
  token_period           = "600"
  renewable              = true
  token_explicit_max_ttl = "14400" # 4h
}

//////////////////////////////////
// Vault | Auth Tokens
//////////////////////////////////

resource "vault_token" "EXAMPLE" {
  role_name = vault_token_auth_backend_role.EXAMPLE.role_name

  policies = [
    "example-policy",
  ]

  renewable = true
  ttl       = "2h"

  renew_min_lease = 600
  renew_increment = 600
}

output "example-token" {
  sensitive = true
  value     = vault_token.EXAMPLE
}

//////////////////////////////////
// Vault | Autopilot
//////////////////////////////////

/*resource "vault_raft_autopilot" "AUTOPILOT" {
  cleanup_dead_servers               = true
  dead_server_last_contact_threshold = "24h0m0s"
  last_contact_threshold             = "10s"
  max_trailing_logs                  = 1000
  min_quorum                         = 1
  server_stabilization_time          = "10s"
}*/

//////////////////////////////////
// Vault | Backups
//////////////////////////////////

/*resource "vault_raft_snapshot_agent_config" "BACKUP" {
  name             = "local"
  interval_seconds = 43200 # 12h
  retain           = 6
  path_prefix      = "/tmp/snapshots/"
  storage_type     = "local"

  # Storage Type Configuration
  local_max_space = 1250000
}*/