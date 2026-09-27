# Short-lived token of whoever runs Terraform (in CI: github-terraform)
data "google_client_config" "current" {}

# Helm talks to the cluster created by the module, with that token
provider "helm" {
  kubernetes {
    host                   = "https://${module.platform.cluster_endpoint}"
    token                  = data.google_client_config.current.access_token
    cluster_ca_certificate = base64decode(module.platform.cluster_ca_certificate)
  }
}

# 1. ArgoCD itself, kept lean: on Autopilot every pod is billed
resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = "10.0.0"
  namespace        = "argocd"
  create_namespace = true
  timeout          = 900 # Autopilot may need to add nodes first

  values = [yamlencode({
    dex            = { enabled = false } # no single sign-on for this lab
    notifications  = { enabled = false }
    applicationSet = { enabled = false }
  })]
}

# 2. The Application: "keep namespace iris in sync with the k8s/ folder of the repo"
resource "helm_release" "iris_app" {
  name       = "iris-apps"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argocd-apps"
  version    = "2.0.5"
  namespace  = "argocd"

  values = [yamlencode({
    applications = {
      iris = {
        namespace = "argocd"
        project   = "default"
        source = {
          repoURL        = "https://github.com/ofsec/gke-iris-platform.git"
          targetRevision = "main"
          path           = "k8s"
        }
        destination = {
          server    = "https://kubernetes.default.svc"
          namespace = "iris"
        }
        syncPolicy = {
          automated = {
            prune    = true # delete what was removed from Git
            selfHeal = true # revert manual changes in the cluster
          }
        }
      }
      # Monitoring: upstream Helm chart + our values file from Git (multi-source)
      prometheus = {
        namespace = "argocd"
        project   = "default"
        sources = [
          {
            repoURL        = "https://prometheus-community.github.io/helm-charts"
            chart          = "prometheus"
            targetRevision = "29.34.0"
            helm           = { valueFiles = ["$values/monitoring/prometheus-values.yaml"] }
          },
          {
            repoURL        = "https://github.com/ofsec/gke-iris-platform.git"
            targetRevision = "main"
            ref            = "values" # makes this repo available as $values
          }
        ]
        destination = {
          server    = "https://kubernetes.default.svc"
          namespace = "monitoring"
        }
        syncPolicy = {
          automated   = { prune = true, selfHeal = true }
          syncOptions = ["CreateNamespace=true"]
        }
      }
      grafana = {
        namespace = "argocd"
        project   = "default"
        sources = [
          {
            repoURL        = "https://grafana-community.github.io/helm-charts"
            chart          = "grafana"
            targetRevision = "13.2.6"
            helm           = { valueFiles = ["$values/monitoring/grafana-values.yaml"] }
          },
          {
            repoURL        = "https://github.com/ofsec/gke-iris-platform.git"
            targetRevision = "main"
            ref            = "values"
          }
        ]
        destination = {
          server    = "https://kubernetes.default.svc"
          namespace = "monitoring"
        }
        syncPolicy = {
          automated   = { prune = true, selfHeal = true }
          syncOptions = ["CreateNamespace=true"]
        }
      }
    }
  })]

  depends_on = [helm_release.argocd]
}
