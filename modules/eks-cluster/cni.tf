###################################################################################################

data "aws_subnet_ids" "container" {
  count  = var.enable_custom_cni ? 1 : 0
  vpc_id = data.aws_vpc.scope.id

  tags = {
    Set  = var.container_subnet_set
    Tier = var.container_subnet_tier
    Zone = "*"
  }
}

data "aws_subnet" "container" {
  id     = tolist(data.aws_subnet_ids.container[0].ids)[count.index]
  count  = var.enable_custom_cni ? length(data.aws_subnet_ids.container[0].ids) : 0
  vpc_id = data.aws_vpc.scope.id
}

###################################################################################################

resource "null_resource" "custom_cni_patch" {
  depends_on = [ null_resource.wait_for_cluster ]

  count = var.enable_custom_cni ? 1 : 0

  triggers = {
    id        = aws_eks_cluster.scope.id
    eniconfig = local.content
  }

  provisioner "local-exec" {
    command = <<-EOF
      kubectl --insecure-skip-tls-verify --token=$TOKEN --server=$API_SERVER set env daemonset aws-node -n kube-system ENI_CONFIG_LABEL_DEF=failure-domain.beta.kubernetes.io/zone;
      kubectl --insecure-skip-tls-verify --token=$TOKEN --server=$API_SERVER set env daemonset aws-node -n kube-system AWS_VPC_K8S_CNI_CUSTOM_NETWORK_CFG=true;
      echo "${local.content}" | kubectl --insecure-skip-tls-verify --token=$TOKEN --server=$API_SERVER apply -f -;
    EOF
    environment = {
      TOKEN = data.aws_eks_cluster_auth.scope.token
      API_SERVER = aws_eks_cluster.scope.endpoint
    }
  }
}

locals {
  content = <<OOF
%{ if var.enable_custom_cni ~}
%{ for index, subnet_id in tolist(data.aws_subnet_ids.container[0].ids) ~}
---
apiVersion: crd.k8s.amazonaws.com/v1alpha1
kind: ENIConfig
metadata:
  name: "${element(data.aws_subnet.container.*.availability_zone, index)}"
spec:
  securityGroups: ${jsonencode(concat([aws_security_group.worker.id], data.aws_security_group.worker-extra-group.*.id))}
  subnet: "${subnet_id}"
%{ endfor ~}
%{ endif ~}
OOF
}

###################################################################################################
