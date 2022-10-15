###################################################################################################

data "aws_caller_identity" "scope" {}

###################################################################################################

data "aws_eks_cluster_auth" "scope" {
  name       =   aws_eks_cluster.scope.name
  depends_on = [ null_resource.wait_for_cluster ]
}

###################################################################################################

resource "null_resource" "wait_for_cluster" {
  depends_on = [aws_eks_cluster.scope]

  triggers = {
    id = aws_eks_cluster.scope.id
  }

  provisioner "local-exec" {
    command     = "until(curl ${aws_eks_cluster.scope.endpoint}/healthz --insecure); do sleep 10; done;"
  }
}

###################################################################################################

resource "null_resource" "aws_auth" {
  depends_on = [ null_resource.wait_for_cluster ]

  triggers = {
    id     = aws_eks_cluster.scope.id
    config = local.aws_auth_config_map
  }

  provisioner "local-exec" {
    command = <<-EOF
      echo "${local.aws_auth_config_map}" | kubectl --insecure-skip-tls-verify --token=$TOKEN --server=$API_SERVER apply -f -;
    EOF
    environment = {
      TOKEN = data.aws_eks_cluster_auth.scope.token
      API_SERVER = aws_eks_cluster.scope.endpoint
    }
  }
}

###################################################################################################

locals {
  aws_auth_config_map = <<EOF
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: aws-auth
  namespace: kube-system
data:
  mapRoles: |
    - rolearn: "arn:aws:iam::${data.aws_caller_identity.scope.account_id}:role/${var.cluster_name}-eks-worker"
      username: system:node:{{EC2PrivateDNSName}}
      groups:
        - system:bootstrappers
        - system:nodes
    - rolearn: "arn:aws:iam::${data.aws_caller_identity.scope.account_id}:role/${var.cluster_name}-spot-eks-worker"
      username: system:node:{{EC2PrivateDNSName}}
      groups:
        - system:bootstrappers
        - system:nodes
%{ for role_arn in var.worker_role_arns ~}
    - rolearn: "${role_arn}"
      username: system:node:{{EC2PrivateDNSName}}
      groups:
        - system:bootstrappers
        - system:nodes
%{ endfor ~}
%{ for cluster_admin_role in var.cluster_admin_role_arns ~}
    - rolearn: "arn:aws:iam::${data.aws_caller_identity.scope.account_id}:role/${cluster_admin_role}"
      username: admin
      groups:
        - system:masters
%{ endfor ~}
EOF
}

###################################################################################################