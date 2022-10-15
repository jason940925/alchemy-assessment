###################################################################################################

data "aws_subnet_ids" "scope" {
  vpc_id = data.aws_vpc.scope.id
  tags = {
    Set  = var.subnet_set
    Tier = var.tier
    Zone = var.zone
  }
}

###################################################################################################

data "aws_subnet" "scope" {
  id    = tolist(data.aws_subnet_ids.scope.ids)[count.index]
  count = length(data.aws_subnet_ids.scope.ids)
}

###################################################################################################

output "subnet_set"   { value = var.subnet_set                        }
output "subnet_ids"   { value = [ data.aws_subnet.scope.*.id        ] }
output "subnet_count" { value =   length(data.aws_subnet.scope)       }
output "subnet_names" { value = [ data.aws_subnet.scope.*.tags.Name ] }

###################################################################################################
