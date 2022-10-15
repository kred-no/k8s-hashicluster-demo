# Custom Configuration
# https://www.vaultproject.io/docs/platform/k8s/helm/examples/standalone-tls
ui = true

listener "tcp" {
  address = "[::]:8200"
  cluster_address = "[::]:8201"
  
  tls_disable        = 0
  tls_client_ca_file = "/vault/tls/ca.pem"
  tls_cert_file      = "/vault/tls/crt.pem"
  tls_key_file       = "/vault/tls/key.pem"
}

storage "raft" {
  path = "/vault/data"
}

#hvs.N3vR57N8RNstTt5R9LWlF3vq
#Zaq78RMHKKxbHmIdEu+XpUWfdbaLhPjT8qWVyFxgeMY=