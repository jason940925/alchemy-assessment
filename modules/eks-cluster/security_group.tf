###################################################################################################

data "aws_security_group" "worker-extra-group" {
  name   = "${var.security_group_vpc_prefix ? format("%v-", data.aws_vpc.scope.tags.Name) : ""}${var.worker_extra_security_groups[count.index]}"
  count  = length(var.worker_extra_security_groups)
  vpc_id = data.aws_vpc.scope.id
}

###################################################################################################

resource "aws_security_group" "control-plane" {
  name   = "${var.security_group_vpc_prefix ? format("%v-", data.aws_vpc.scope.tags.Name) : ""}${format("%v-eks-perimeter-control-plane", var.cluster_name)}"
  vpc_id = data.aws_vpc.scope.id

  tags = {
    VPC                                         = var.vpc_name
    Name                                        = "${var.security_group_vpc_prefix ? format("%v-", data.aws_vpc.scope.tags.Name) : ""}${format("%v-eks-perimeter-control-plane", var.cluster_name)}"
    NameShort                                   = format("%v-eks-perimeter-control-plane", var.cluster_name)
    Region                                      = data.aws_region.scope.name
    CostCenter                                  = var.cost_center
    OwnerContact                                = var.owner_contact
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
  }
}

resource "aws_security_group_rule" "workers-to-api-server" {
  type                     = "ingress"
  to_port                  = 443
  protocol                 = "tcp"
  from_port                = 443
  security_group_id        = aws_security_group.control-plane.id
  source_security_group_id = aws_security_group.worker.id
}

resource "aws_security_group_rule" "api-server-to-workers" {
  type                     = "egress"
  to_port                  = 65535
  protocol                 = "tcp"
  from_port                = 1025
  security_group_id        = aws_security_group.control-plane.id
  source_security_group_id = aws_security_group.worker.id
}

###################################################################################################

resource "aws_security_group" "worker" {
  name   = "${var.security_group_vpc_prefix ? format("%v-", data.aws_vpc.scope.tags.Name) : ""}${format("%v-eks-perimeter-worker", var.cluster_name)}"
  vpc_id = data.aws_vpc.scope.id

  tags = {
    VPC                                         = var.vpc_name
    Name                                        = "${var.security_group_vpc_prefix ? format("%v-", data.aws_vpc.scope.tags.Name) : ""}${format("%v-eks-perimeter-worker", var.cluster_name)}"
    NameShort                                   = format("%v-eks-perimeter-worker", var.cluster_name)
    Region                                      = data.aws_region.scope.name
    CostCenter                                  = var.cost_center
    OwnerContact                                = var.owner_contact
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
  }
}

resource "aws_security_group_rule" "control-plane-to-workers-https" {
  type                     = "ingress"
  to_port                  = 443
  protocol                 = "tcp"
  from_port                = 443
  security_group_id        = aws_security_group.worker.id
  source_security_group_id = aws_security_group.control-plane.id
}

resource "aws_security_group_rule" "control-plane-to-workers-range" {
  type                     = "ingress"
  to_port                  = 65535
  protocol                 = "tcp"
  from_port                = 1025
  security_group_id        = aws_security_group.worker.id
  source_security_group_id = aws_security_group.control-plane.id
}

resource "aws_security_group_rule" "workers-to-workers" {
  self                     = true
  type                     = "ingress"
  to_port                  = 65535
  protocol                 = "all"
  from_port                = 0
  security_group_id        = aws_security_group.worker.id
}

resource "aws_security_group_rule" "workers-egress" {
  type                     = "egress"
  to_port                  = 65535
  protocol                 = "all"
  from_port                = 0
  cidr_blocks              = ["0.0.0.0/0"]
  security_group_id        = aws_security_group.worker.id
}

###################################################################################################

output "worker_security_group_id"          { value = aws_security_group.worker.id                          }
output "security_group_vpc_prefix"         { value = var.security_group_vpc_prefix                         }
output "worker_security_group_name"        { value = aws_security_group.worker.name                        }
output "worker_extra_security_groups"      { value = [ data.aws_security_group.worker-extra-group.*.id   ] }
output "worker_extra_security_group_count" { value = length(var.worker_extra_security_groups)              }
output "worker_extra_security_group_names" { value = [ data.aws_security_group.worker-extra-group.*.name ] }

###################################################################################################
