provider "kubernetes" {
  alias  = "eks"
  host   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  token  = data.aws_eks_cluster_auth.eks.token
}

resource "kubernetes_deployment" "deployment" {
  provider = kubernetes.eks
  metadata {
    name = var.project_name
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = var.project_name
      }
    }

    template {
      metadata {
        labels = {
          app = var.project_name
        }
      }

      spec {
        container {
          image = data.aws_ecr_repository.repo.repository_url
          name  = var.project_name
        }
      }
    }
  }
}