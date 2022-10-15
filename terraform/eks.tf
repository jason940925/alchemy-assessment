module "eks" {
  source = "../modules/eks-cluster"
#   vpc_name                     = "${var.account_name}-app"
  vpc_name                     = "dx-mobile-nonprod-app"
  environment                  = var.environment
  cluster_name                 = format("%v-%v-%v", var.application, var.property, var.environment)
  kubernetes_version           = var.kubernetes_version
#   public_access_cidrs          = var.eks_public_access_cidrs
  cluster_admin_role_arns      = [ "${var.account_name}-eks-admin" ]
  security_group_vpc_prefix    = true
  worker_extra_security_groups = [ "eks-worker" ]
}
