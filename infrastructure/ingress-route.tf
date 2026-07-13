resource "kubernetes_manifest" "mlflow_ingressroute" {
  manifest = {
    apiVersion = "traefik.io/v1alpha1"
    kind       = "IngressRoute"
    metadata = {
      name      = "mlflow"
      namespace = "mlflow"
    }
    spec = {
      routes = [{
        match = "Host(`${data.aws_lb.traefik.dns_name}`)"
        kind  = "Rule"
        services = [{ name = "mlflow", port = 5000 }]
      }]
    }
  }
}