# VPC id
output "vpc_id" {
  value = aws_vpc.vpc.id
}
// NAT ips.
output "nat_ips" {
  value = [aws_eip.eip_primary.public_ip, aws_eip.eip_secondary.public_ip]
}
// Public subnet IDs.
output "public_subnets_id" {
  value = [aws_subnet.public_primary.id, aws_subnet.public_secondary.id]
}

// Private subnet IDs.
output "private_subnets_id" {
  value = [aws_subnet.private_primary.id, aws_subnet.private_secondary.id]
}
//
// Data subnet IDs.
output "data_subnets_id" {
  value = [aws_subnet.data_primary.id, aws_subnet.data_secondary.id]
}

output "public_subnets_cidr" {
  value = [aws_subnet.public_primary.cidr_block, aws_subnet.public_secondary.cidr_block]
}

// Private subnet IDs.
output "private_subnets_cidr" {
  value = [aws_subnet.private_primary.cidr_block, aws_subnet.private_secondary.cidr_block]
}
//
// Data subnet IDs.
output "data_subnets_cidr" {
  value = [aws_subnet.data_primary.cidr_block, aws_subnet.data_secondary.cidr_block]
}

output "private_subnet_route_table" {
  value = [aws_route_table.private_primary.id, aws_route_table.private_secondary.id]
}

output "data_subnet_route_table" {
  value = [aws_route_table.data_primary.id, aws_route_table.data_secondary.id]
}


