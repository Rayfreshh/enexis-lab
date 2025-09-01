resource "helm_release" "ingress_nginx" {
  name             = "ingress-nginx"
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  version          = "4.13.2"
  namespace        = "ingress-nginx"
  create_namespace = true
  timeout          = 900

  set {
    name  = "controller.service.loadBalancerIP"
    value = "50.85.20.181"
  }
}

resource "kubernetes_ingress_v1" "enexis_ingress" {
  metadata {
    name      = "enexis-ingress"
    namespace = "default"
  }

  spec {
    ingress_class_name = "nginx"

    rule {
      host = "enexis-app.westeurope.cloudapp.azure.com"

      http {
        path {
          path      = "/"
          path_type = "Prefix"

          backend {
            service {
              name = "enexis-microservice"
              port {
                number = 8000
              }
            }
          }
        }
      }
    }
  }
}