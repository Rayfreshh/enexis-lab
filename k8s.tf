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
    name  = "controller.service.annotations.\"service\\.beta\\.kubernetes\\.io/azure-load-balancer-resource-group\""
    value = "MC_enexis-lab-rg_enexis-lab-aks_westeurope"
  }
}

resource "kubernetes_service" "microservice" {
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
    }
    type = "ClusterIP"
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
    ingress_class_name = "nginx"
    rule {
      host = "app.enexis.test"
      http {
        path {
          path     = "/"
          path_type = "Prefix"
          backend {
            service {
              name = kubernetes_service.microservice.metadata[0].name
              port {
                number = 80
              }
            }
          }
        }
      }
    }
    tls {
      hosts       = ["app.enexis.test"]
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
        server = "https://acme-v02.api.letsencrypt.org/directory"
        email  = "samsonraymond63@yahoo.com"
        privateKeySecretRef = {
          name = "letsencrypt-http"
        }
        solvers = [
          {
            http01 = {
              ingress = {
                class = "nginx"
              }
            }
          }
        ]
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
      dnsNames   = ["app.enexis.test"]
      issuerRef = {
        name = "letsencrypt-http"
        kind = "ClusterIssuer"
      }
    }
  }
}
