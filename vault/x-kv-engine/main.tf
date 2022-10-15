//////////////////////////////////
// Enable kv mount/engine
//////////////////////////////////

resource "vault_mount" "KVV2" {
  path        = "kvv2"
  description = "KV Version 2 secret engine mount"
  type        = "kv"
  
  options     = {
    version = "2"
  }

}

//////////////////////////////////
// Create example secret(s)
//////////////////////////////////

resource "vault_kv_secret_v2" "DEMO" {
  mount = vault_mount.KVV2.path
  name  = "secret"
  cas   = 1
  
  delete_all_versions = true
  
  data_json = jsonencode({
    zip       = "zap",
    foo       = "bar",
    hey       = "ho",
  })
}
