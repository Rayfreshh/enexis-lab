resource "helm_release" "ingress_nginx" {
  name       = "ingress-nginx"
  namespace  = "ingress-nginx"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"

  set {
    name  = "controller.service.type"
    value = "LoadBalancer"
  }

  set {
    name  = "controller.service.loadBalancerIP"
    value = "50.85.20.181"   # existing static IP in your node RG
  }
}

resource "kubernetes_ingress_v1" "enexis_ingress" {
  metadata {
    name      = "enexis-ingress"
    namespace = "default"
    annotations = {
      "kubernetes.io/ingress.class" : "nginx"
    }
  }

  spec {
    rule {
      http {
        path {
          path     = "/"
          path_type = "Prefix"
          backend {
            service {
              name = "example-service"   # replace with your service name
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
