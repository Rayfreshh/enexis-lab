resource "helm_release" "ingress_nginx" {
  name             = "ingress-nginx"
  namespace        = "ingress-nginx"
  create_namespace = true

  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  version    = "4.13.2"

  set {
    name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/azure-load-balancer-resource-group"
    value = "MC_enexis-lab-rg_enexis-lab-aks_westeurope"
  }

  set {
    name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/azure-load-balancer-health-probe-request-path"
    value = "/healthz"
  }

  set {
    name  = "controller.service.loadBalancerIP"
    value = "50.85.20.181"
  }
}

resource "helm_release" "cert_manager" {
  name             = "cert-manager"
  namespace        = "cert-manager"
  create_namespace = true

  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  version    = "v1.14.4"

  set {
    name  = "installCRDs"
    value = "true"
  }
}

resource "kubernetes_manifest" "letsencrypt_clusterissuer" {
  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"
    metadata = {
      name = "letsencrypt-http"
    }
    spec = {
      acme = {
        server = "https://acme-v02.api.letsencrypt.org/directory"
        email  = "samsonraymond63@yahoo.com"
        privateKeySecretRef = {
          name = "letsencrypt-account-key"
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

resource "kubernetes_service" "enexis_microservice" {
  metadata {
    name      = "enexis-microservice-service"
    namespace = "default"
  }

  spec {
    selector = {
      app = "enexis-microservice"
    }

    port {
      port        = 80
      target_port = 8000
      protocol    = "TCP"
    }

    type = "ClusterIP"
  }
}

resource "kubernetes_ingress_v1" "enexis_ingress" {
  metadata {
    name      = "enexis-ingress"
    namespace = "default"
    annotations = {
      "kubernetes.io/ingress.class"    = "nginx"
      "cert-manager.io/cluster-issuer" = "letsencrypt-http"
      "nginx.ingress.kubernetes.io/force-ssl-redirect" = "true"
    }
  }

  spec {
    tls {
      hosts       = ["50.85.20.181.nip.io"]
      secret_name = "enexis-tls"
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
  }
}

output "ingress_url" {
  description = "Public HTTPS URL to access the microservice"
  value       = "https://50.85.20.181.nip.io"
}
