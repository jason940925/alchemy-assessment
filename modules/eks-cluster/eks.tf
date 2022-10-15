###################################################################################################

resource "aws_eks_cluster" "scope" {
  name                      = var.cluster_name
  version                   = var.kubernetes_version
  role_arn                  = aws_iam_role.scope.arn
  enabled_cluster_log_types = var.cluster_log_types

  vpc_config {
    subnet_ids              = data.aws_subnet_ids.scope.ids
    security_group_ids      = [aws_security_group.control-plane.id]
    public_access_cidrs     = var.public_access_cidrs
    endpoint_public_access  = var.endpoint_public_access
    endpoint_private_access = var.endpoint_private_access
  }

  encryption_config {
    provider {
      key_arn = aws_kms_key.eks.arn
    }
    resources = var.encrypted_cluster_resources
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks-service-policy,
    aws_iam_role_policy_attachment.eks-cluster-policy,
    aws_cloudwatch_log_group.scope,
  ]

  provisioner "local-exec" {
    when    = destroy
    command = "python3 ${path.module}/scripts/aws-elb-cleanup.py ${self.name} ${self.tags.Region}"
  }

  tags = {
    VPC          = data.aws_vpc.scope.tags.Name
    Name         = var.cluster_name
    Region       = data.aws_region.scope.name
    CostCenter   = var.cost_center
    Environment  = var.environment
    OwnerContact = var.owner_contact
  }

}

###################################################################################################

resource "aws_kms_key" "eks" {
  key_usage                = "ENCRYPT_DECRYPT"
  is_enabled               = true
  description              = format("%v-eks-cluster-key", var.cluster_name)
  enable_key_rotation      = true
  deletion_window_in_days  = var.kms_key_deletion_window
  customer_master_key_spec = "SYMMETRIC_DEFAULT"

  tags = {
    VPC          = data.aws_vpc.scope.tags.Name
    Name         = format("%v-eks-cluster-key", var.cluster_name)
    Region       = data.aws_region.scope.name
    CostCenter   = var.cost_center
    Environment  = var.environment
    OwnerContact = var.owner_contact
  }
}

###################################################################################################

resource "aws_iam_role" "scope" {
  name = format("%v-eks-cluster-role", var.cluster_name)

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "eks-cluster-policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.scope.name
}

resource "aws_iam_role_policy_attachment" "eks-service-policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = aws_iam_role.scope.name
}

###################################################################################################

data "aws_iam_policy_document" "cluster_elb_sl_role_creation" {

  statement {
    effect = "Allow"
    actions = [
      "ec2:DescribeAccountAttributes",
      "ec2:DescribeInternetGateways"
    ]
    resources = ["*"]
  }

}

resource "aws_iam_role_policy" "cluster_elb_sl_role_creation" {
  role        = aws_iam_role.scope.name
  policy      = data.aws_iam_policy_document.cluster_elb_sl_role_creation.json
  name_prefix = format("%v-eks-elb-role-policy", var.cluster_name)
}

###################################################################################################

resource "aws_cloudwatch_log_group" "scope" {
  name              = "/aws/eks/${var.cluster_name}/cluster"
  retention_in_days = var.cluster_log_retention
}

###################################################################################################

output "id" {
  value      =   aws_eks_cluster.scope.id
  depends_on = [ null_resource.wait_for_cluster ]
}

output "cluster_name" {
  value      =   aws_eks_cluster.scope.name
  depends_on = [ null_resource.wait_for_cluster ]
}

###################################################################################################

output "arn"                                   { value = aws_eks_cluster.scope.arn                                    }
output "status"                                { value = aws_eks_cluster.scope.status                                 }
output "endpoint"                              { value = aws_eks_cluster.scope.endpoint                               }
output "oidc_issuer"                           { value = aws_eks_cluster.scope.identity[0].oidc[0].issuer             }
output "aws_eks_cluster"                       { value = aws_eks_cluster.scope                                        }
output "platform_version"                      { value = aws_eks_cluster.scope.platform_version                       }
output "kubernetes_version"                    { value = aws_eks_cluster.scope.version                                }
output "cluster_security_group_id"             { value = aws_eks_cluster.scope.vpc_config.0.cluster_security_group_id }
output "kubeconfig-certificate-authority-data" { value = aws_eks_cluster.scope.certificate_authority.0.data           }

###################################################################################################