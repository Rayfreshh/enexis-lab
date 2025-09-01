resource "helm_release" "ingress_nginx" {
  name       = "ingress-nginx"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  namespace  = "ingress-nginx"

  values = [
    <<EOF
controller:
  service:
    loadBalancerIP: 50.85.20.181
    annotations:
      service.beta.kubernetes.io/azure-load-balancer-resource-group: MC_enexis-lab-rg_enexis-lab-aks_westeurope
      service.beta.kubernetes.io/azure-load-balancer-health-probe-request-path: /healthz
EOF
  ]
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
          path     = "/"
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

resource "kubernetes_service_v1" "microservice" {
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
