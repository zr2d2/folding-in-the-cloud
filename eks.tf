module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  cluster_name    = var.project_name
  cluster_version = "1.29"

  vpc_id          = aws_vpc.vpc.id
  subnet_ids      = [aws_subnet.public_subnet1.id,aws_subnet.public_subnet2.id]

  cluster_endpoint_public_access	= true
  cluster_endpoint_public_access_cidrs = var.external_ips

  access_entries = {
    # One access entry with a policy associated
    Admins = {
      kubernetes_groups = []
      principal_arn     = "arn:aws:iam::123456789012:role/something"

      policy_associations = {
        admin_association = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            namespaces = ["default"]
            type       = "namespace"
          }
        }
      }
    }
  }

  eks_managed_node_groups = {
    eks_node_group = {
      vpc_security_group_ids = [aws_security_group.security_group.id]
      eks_nodes = {
        desired_capacity = 1
        max_capacity     = 1
        min_capacity     = 1

        instance_type = "m5.medium"
        key_name      = "zach thinkpad t14"
      }
    }
  }
}

data "aws_ecr_repository" "repo" {
  name = "${var.project_name}"
}

resource "aws_ecr_repository_policy" "_repo_policy" {
  repository = data.aws_ecr_repository.repo.name

  policy = <<EOF
{
  "Version": "2008-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": "*",
      "Action": [
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchCheckLayerAvailability",
        "ecr:BatchGetImage",
        "ecr:InitiateLayerUpload",
        "ecr:UploadLayerPart",
        "ecr:CompleteLayerUpload",
        "ecr:PutImage"
      ]
    }
  ]
}
EOF
}

output "eks_cluster_name" {
  value = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "eks_cluster_certificate_authority_data" {
  value = module.eks.cluster_certificate_authority_data
}

data "aws_eks_cluster_auth" "eks" {
  name = module.eks.cluster_name
}
