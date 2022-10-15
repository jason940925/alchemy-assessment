```bash
data "aws_caller_identity" "scope" {}

# For worker_role_arns please see one of the terraform modules for workers

module "eks-cluster" {
  source                       = "git::ssh://git@gitlab.melco-janus.com/dx-platform/terraform-modules/aws/terraform-module-aws-eks-cluster.git?ref=v1.0.0"
  name                         = "my_awesome_cluster"
  vpc_name                     = "vpc_name"
  environment                  = "prod"
  worker_role_arns             = [ "module.eks-spot.iam_role_arn" ]
  kubernetes_version           = "1.17"
  public_access_cidrs          = [ "0.0.0.0/0" ]
  cluster_admin_role_arns      = [ "arn:aws:iam::${data.aws_caller_identity.scope.account_id}:role/${var.account_name}-app-eks-admin" ]
  security_group_vpc_prefix    = true
  worker_extra_security_groups = [ "eks-worker" ]
}
```