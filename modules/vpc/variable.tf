variable "cidr_block" {
  description = "The cidr block of the vpc. "
}
variable "account_name" {
  description = "The name of the account which the resources are deployed in. "
}

variable "cluster_name" {
  type        = list(string)
  description = "The name of the EKS cluster"
}

variable "application_name" {
  description = "The name of the application. e.g.'app','cicd' "
}

variable "eks_enabled" {
  type        = bool
  description = "If set to true, the eks tag will add to vpc and subnet. "
  default     = true
}

variable "cidr_block_secondary" {
  description = "The secondary CIDR block for the VPC"
  default     = "100.64.0.0/16"
}

variable "enable_container_subnet" {
  type        = bool
  description = "Enable container subnet creation. This will create secondary CIDR block in VPC and subnet for container"
  default     = true
}

variable "public_subnet_custom_tags" {
  type        = map(string)
  default     = {}
  description = "Custom tags for public subnet"
}

variable "private_subnet_custom_tags" {
  type        = map(string)
  default     = {}
  description = "Custom tags for private subnet"
}

variable "data_subnet_custom_tags" {
  type        = map(string)
  default     = {}
  description = "Custom tags for data subnet"
}

variable "container_subnet_custom_tags" {
  type        = map(string)
  default     = {}
  description = "Custom tags for cotainer subnet"
}

variable "enable_vpn_connection" {
  type        = bool
  description = "Enable VPN connection"
  default     = false
}

variable "bgp_asn_primary" {
  default     = ""
  description = "The bgp asn number of primary customer gateway."
}

variable "bgp_asn_secondary" {
  default     = ""
  description = "The bgp asn number of secondary customer gateway. "
}

variable "cgw_ip_primary" {
  default     = ""
  description = "The ip address of primary customer gateway. "
}

variable "cgw_ip_secondary" {
  default     = ""
  description = "The ip address of secondary customer gateway."
}

variable "subnet_public_tier" {
  default     = "public"
  description = "Public subnet tier tag value"
}

variable "subnet_public_set" {
  default = "default"
  description = "Public subnet set tag value"
}

variable "subnet_private_tier" {
  default     = "private"
  description = "Private subnet tier tag value"
}

variable "subnet_private_set" {
  default     = "default"
  description = "Private subnet set tag value"
}

variable "subnet_data_tier" {
  default     = "private"
  description = "Data subnet tier tag value"
}

variable "subnet_data_set" {
  default     = "data"
  description = "Data subnet set tag value"
}

variable "subnet_container_tier" {
  default     = "private"
  description = "Container subnet tier tag value"
}

variable "subnet_container_set" {
  default     = "container"
  description = "Container subnet set tag value"
}
