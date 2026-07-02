resource "helm_release" "secrets_store_csi_driver" {
  name       = "csi-secrets-store"
  repository = "https://kubernetes-sigs.github.io/secrets-store-csi-driver/charts"
  chart      = "secrets-store-csi-driver"
  namespace  = "kube-system"

  depends_on = [aws_eks_node_group.main]
}

resource "helm_release" "secrets_store_csi_driver_provider_aws" {
  name       = "secrets-provider-aws"
  repository = "https://aws.github.io/secrets-store-csi-driver-provider-aws"
  chart      = "secrets-store-csi-driver-provider-aws"
  namespace  = "kube-system"

  set = [
    {
      name  = "secrets-store-csi-driver.install"
      value = "false"
    }
  ]

  depends_on = [helm_release.secrets_store_csi_driver]
}

resource "helm_release" "traefik" {
  name             = "traefik"
  repository       = "https://traefik.github.io/charts"
  chart            = "traefik"
  namespace        = "traefik"
  create_namespace = true

  set = [
    {
      name  = "ports.web.port"
      value = "8000"
    },
    {
      name  = "ports.websecure.port"
      value = "8443"
    },
    {
      name  = "service.type"
      value = "LoadBalancer"
    }
  ]

  depends_on = [aws_eks_node_group.main]
}

# Read back the Traefik Service's LB hostname so it can be used
# as the dynamic IngressRoute host (replaces the hardcoded value).
data "kubernetes_service" "traefik" {
  metadata {
    name      = "traefik"
    namespace = "traefik"
  }
  depends_on = [helm_release.traefik]
}