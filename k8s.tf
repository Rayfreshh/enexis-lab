resource "helm_release" "ingress_nginx" {
  name             = "ingress-nginx"
  namespace        = "ingress-nginx"
  create_namespace = true

  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"

  timeout       = 600
  wait          = true
  force_update  = true
  recreate_pods = true

  set {
    name  = "controller.service.type"
    value = "LoadBalancer"
  }

  set {
    name  = "controller.service.loadBalancerIP"
    value = "50.85.20.181"
  }

  set {
    name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/azure-load-balancer-resource-group"
    value = "MC_enexis-lab-rg_enexis-lab-aks_westeurope"
  }

  set {
    name  = "controller.admissionWebhooks.enabled"
    value = "false"
  }
}

# ✅ Corrected microservice Service (ClusterIP only)
resource "kubernetes_service_v1" "enexis_microservice" {
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

# ✅ Ingress pointing to the service
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
              name = kubernetes_service_v1.enexis_microservice.metadata[0].name
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }

  depends_on = [helm_release.ingress_nginx]
}
