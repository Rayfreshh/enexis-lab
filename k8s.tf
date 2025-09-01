resource "kubernetes_namespace" "ingress_nginx" {
  metadata {
    name = "ingress-nginx"
  }
}

resource "helm_release" "ingress_nginx" {
  name       = "ingress-nginx"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  namespace  = kubernetes_namespace.ingress_nginx.metadata[0].name
  version    = "4.13.2"

  set {
    name  = "controller.service.loadBalancerIP"
    value = "50.85.20.181"
  }

  set {
    name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/azure-load-balancer-resource-group"
    value = "MC_enexis-lab-rg_enexis-lab-aks_westeurope"
  }
}

resource "kubernetes_ingress_v1" "enexis_ingress" {
  metadata {
    name      = "enexis-ingress"
    namespace = "default"
    annotations = {
      "kubernetes.io/ingress.class" = "nginx"
    }
  }

  spec {
    rule {
      host = "app.enexis.test"
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = kubernetes_service.enexis_microservice.metadata[0].name
              port {
                number = 80
              }
            }
          }
        }
      }
    }

    rule {
      host = "50.85.20.181.nip.io"
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = kubernetes_service.enexis_microservice.metadata[0].name
              port {
                number = 80
              }
            }
          }
        }
      }
    }

    tls {
      hosts       = ["50.85.20.181.nip.io"]
      secret_name = "enexis-tls"
    }
  }
}

resource "kubernetes_manifest" "letsencrypt_http" {
  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"
    metadata = {
      name = "letsencrypt-http"
    }
    spec = {
      acme = {
        server   = "https://acme-staging-v02.api.letsencrypt.org/directory"
        email    = "samsonraymond63@yahoo.com"
        privateKeySecretRef = {
          name = "letsencrypt-http"
        }
        solvers = [{
          http01 = {
            ingress = {
              class = "nginx"
            }
          }]
        }
      }
    }
  }
}

resource "kubernetes_manifest" "enexis_certificate" {
  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "Certificate"
    metadata = {
      name      = "enexis-tls"
      namespace = "default"
    }
    spec = {
      secretName = "enexis-tls"
      issuerRef = {
        name = "letsencrypt-http"
        kind = "ClusterIssuer"
      }
      dnsNames = ["50.85.20.181.nip.io"]
    }
  }
}

output "ingress_url" {
  description = "Public HTTPS URL to access the microservice"
  value       = "https://50.85.20.181.nip.io"
}

output "tls_certificate_check" {
  description = "Command to check if the TLS certificate has been issued"
  value       = "kubectl get certificate enexis-tls -n default -o wide"
}

output "tls_secret_check" {
  description = "Command to check if the TLS secret exists"
  value       = "kubectl get secret enexis-tls -n default -o yaml"
}

output "tls_wait_ready" {
  description = "Wait until the certificate is marked Ready"
  value       = "kubectl wait --for=condition=Ready certificate/enexis-tls -n default --timeout=300s"
}
