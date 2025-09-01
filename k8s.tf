resource "helm_release" "ingress_nginx" {
  name             = "ingress-nginx"
  namespace        = "ingress-nginx"
  create_namespace = true

  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"

  # Force LoadBalancer type
  set {
    name  = "controller.service.type"
    value = "LoadBalancer"
  }

  # Bind to your existing static IP
  set {
    name  = "controller.service.loadBalancerIP"
    value = "50.85.20.181"
  }

  # Disable admission webhook (avoids TLS validation issues in Terraform Cloud)
  set {
    name  = "controller.admissionWebhooks.enabled"
    value = "false"
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
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = "enexis-microservice-service"
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
