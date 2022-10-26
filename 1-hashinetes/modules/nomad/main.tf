// See https://github.com/kelseyhightower/nomad-on-kubernetes

//////////////////////////////////
// Kubernetes | Stateful-Set (Pods)
//////////////////////////////////

resource "kubernetes_stateful_set_v1" "MAIN" {
  metadata {
    name      = join("-", [var.config.name, "server"])
    namespace = kubernetes_namespace_v1.MAIN.metadata.0.name
  }
  
  spec {
    replicas     = 1
    service_name = kubernetes_service_v1.MAIN.metadata.0.name

    selector {
      match_labels = {
        app = var.config.name
      }
    }
    
    // Pod 
    template {
      metadata {
        name = var.config.name
        labels = {
          app = var.config.name
        }
      }

      spec {
        service_account_name             = kubernetes_service_account_v1.MAIN.metadata.0.name
        termination_grace_period_seconds = 30
        dns_policy                       = "ClusterFirstWithHostNet"
        
        # kubectl -n nomad logs pod/nomad-server-0 -c init-config
        /*init_container {
          name              = "init-config"
          image             = "busybox:latest"
          image_pull_policy = "IfNotPresent"
          
          env {
            name = "NODE_IP"
            value_from {
              field_ref {
                field_path = "status.hostIP"
              }
            }
          }

          env {
            name = "NODE_NAME"
            value_from {
              field_ref {
                field_path = "spec.nodeName"
              }
            }
          }
          
          volume_mount {
            name       = "nomad-shared"
            mount_path = "/etc/nomad/nomad.x"
          }
          
          command = ["sh","-c"]
          args = [
            "printf 'advertise {\n  rpc = \"$(NODE_IP):4647\"\n  serf = \"$(NODE_IP):4648\"\n}' | tee /etc/nomad/nomad.x/advertise.hcl",
          ]
        }*/

        container {
          name              = join("-", [var.config.name, "server"])
          image             = join(":",[var.config.image_name,var.config.image_version])
          image_pull_policy = "IfNotPresent"
          
          env {
            name = "NODE_IP"
            value_from {
              field_ref {
                field_path = "status.hostIP"
              }
            }
          }

          env {
            name = "NODE_NAME"
            value_from {
              field_ref {
                field_path = "spec.nodeName"
              }
            }
          }
          
          volume_mount {
            name       = "nomad-config"
            mount_path = "/etc/nomad/nomad.d"
            read_only  = false
          }
          
          volume_mount {
            name       = "nomad-shared"
            mount_path = "/etc/nomad/nomad.x"
            read_only  = true
          }

          volume_mount {
            name       = "nomad-data"
            mount_path = "/var/lib/nomad"
            sub_path   = ""
          }

          args = [
            "agent",
            "-bind=0.0.0.0",
            "-config=/etc/nomad/nomad.d/",
            #"-config=/etc/nomad/nomad.x/advertise.hcl",
          ]
          
          port {
            name           = "http"
            container_port = 4646
            protocol       = "TCP"
          }
          
          port {
            name           = "rcp"
            container_port = 4647
            host_port      = 4647 // Required for connecting external agents
            protocol       = "TCP"
          }

          port {
            name           = "serf-tcp"
            container_port = 4648
            protocol       = "TCP"
          }
          
          port {
            name           = "serf-udp"
            container_port = 4648
            protocol       = "UDP"
          }
          
          resources {
            limits = {
              cpu    = "300m"
              memory = "300Mi"
            }
            requests = {
              cpu    = "100m"
              memory = "150Mi"
            }
          }
        }

        container {
          name              = "consul"
          image             = join(":",["consul",var.config.consul_version])
          image_pull_policy = "IfNotPresent"

          /*env {
            name = "GOSSIP_ENCRYPTION_KEY"
            value_from {
              secret_key_ref {
                name = "consul"
                key  = "gossip-encryption-key"
              }
            }
          }*/
          
          env {
            name = "NAMESPACE"
            value_from {
              field_ref {
                field_path = "metadata.namespace"
              }
            }
          }

          args = [
            "agent",
            "-config-dir=/etc/consul/consul.d/",
            "-data-dir=/var/lib/consul",
            "-datacenter=dc1",
            "-domain=consul",
            "-disable-host-node-id",
            "-retry-join=consul-server.consul.svc.cluster.local:8301",
          ]
          
          resources {
            limits = {
              cpu    = "150m"
              memory = "150Mi"
            }
            requests = {
              cpu    = "75m"
              memory = "75Mi"
            }
          }

          volume_mount {
            name       = "consul-config"
            mount_path = "/etc/consul/consul.d"
            read_only  = true
          }
          
          volume_mount {
            name       = "consul-data"
            mount_path = "/var/lib/consul"
            sub_path   = ""
          }
        }
        
        security_context {
          fs_group  = 1000
        }
        
        volume {
          name = "nomad-shared"
          empty_dir {}
        }

        volume {
          name = "nomad-config"
          config_map {
            name = kubernetes_config_map_v1.NOMAD_CONFIG.metadata.0.name
          }
        }

        volume {
          name = "consul-config"
          config_map {
            name = kubernetes_config_map_v1.CONSUL_CONFIG.metadata.0.name
          }
        }
      }
    }

    volume_claim_template {
      metadata {
        name      = "nomad-data"
        namespace = kubernetes_namespace_v1.MAIN.metadata.0.name
      }

      spec {
        access_modes = ["ReadWriteOnce"]
        
        resources {
          requests = {
            storage = "5Gi"
          }
        }
      }
    }
    
    volume_claim_template {
      metadata {
        name      = "consul-data"
        namespace = kubernetes_namespace_v1.MAIN.metadata.0.name
      }

      spec {
        access_modes = ["ReadWriteOnce"]
        
        resources {
          requests = {
            storage = "5Gi"
          }
        }
      }
    }
  }
}

//////////////////////////////////
// Kubernetes | Config Maps
//////////////////////////////////

resource "kubernetes_config_map_v1" "NOMAD_CONFIG" {
  metadata {
    name      = "nomad"
    namespace = kubernetes_namespace_v1.MAIN.metadata.0.name
  }

  data = {
    "server.hcl" = <<-HEREDOC
    data_dir  = "/var/lib/nomad"
    server {
      enabled = true
      bootstrap_expect = 1
      retry_join = [
        "nomad-server-0.nomad-server.nomad.svc.cluster.local:4648",
      ]
      consul {
        token = ""
      }
    }
    HEREDOC
  }
}

resource "kubernetes_config_map_v1" "CONSUL_CONFIG" {
  metadata {
    name      = "consul"
    namespace = kubernetes_namespace_v1.MAIN.metadata.0.name
  }

  data = {
    "consul.hcl" = <<-HEREDOC
    server     = false
    log_level  = "INFO"
    
    acl {
      enabled = true
      tokens {
        default = "${data.kubernetes_secret_v1.CONSUL_ACL_TOKEN.data.token}"
      }
    }
    
    auto_encrypt {
      tls = true
    }

    encrypt                 = "${data.kubernetes_secret_v1.CONSUL_ENCRYPTION_KEY.data.key}"
    encrypt_verify_incoming = false
    encrypt_verify_outgoing = true
    leave_on_terminate      = true
    HEREDOC
  }
}

//////////////////////////////////
// Kubernetes | Consul Secrets
//////////////////////////////////

data "kubernetes_secret_v1" "CONSUL_ENCRYPTION_KEY" {
  metadata {
    name      = var.config.consul_encryption_secret_name
    namespace = var.config.consul_secrets_namespace
  }
}

data "kubernetes_secret_v1" "CONSUL_ACL_TOKEN" {
  metadata {
    name      = var.config.consul_acl_token_secret_name
    namespace = var.config.consul_secrets_namespace
  }
}

//////////////////////////////////
// Kubernetes | Service
//////////////////////////////////

resource "kubernetes_service_v1" "MAIN" {
  
  metadata {
    name      = join("-", [var.config.name, "ui"])
    namespace = kubernetes_namespace_v1.MAIN.metadata.0.name
    
    labels = {
      app = var.config.name
    }
  }

  spec {
    type = "ClusterIP"

    selector = {
      app = var.config.name
    }
    
    port {
      name        = "http"
      port        = 4646
      target_port = 4646
      protocol    = "TCP"
    }

    port {
      name        = "rcp"
      port        = 4647
      target_port = 4647
      protocol    = "TCP"
    }
  }
}

//////////////////////////////////
// Kubernetes | Service Account
//////////////////////////////////

resource "kubernetes_service_account_v1" "MAIN" {
  metadata {
    name      = join("-", [var.config.name, "server"])
    namespace = kubernetes_namespace_v1.MAIN.metadata.0.name
  }
}

//////////////////////////////////
// Kubernetes | Namespace
//////////////////////////////////

resource "kubernetes_namespace_v1" "MAIN" {
  metadata {
    name = var.config.namespace
  }
}
