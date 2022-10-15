###################################################################################################

variable "vpc_name"     {}
variable "environment"  {}
variable "cluster_name" {}

###################################################################################################

variable "tier"                         { default = "private"        }
variable "zone"                         { default = "*"              }
variable "subnet_set"                   { default = "default"        }
variable "enable_custom_cni"            { default = true             }
variable "public_access_cidrs"          { default = ["127.0.0.1/32"] }
variable "container_subnet_set"         { default = "container"      }
variable "container_subnet_tier"        { default = "private"        }
variable "endpoint_public_access"       { default = true             }
variable "endpoint_private_access"      { default = true             }
variable "security_group_vpc_prefix"    { default = false            }
variable "worker_extra_security_groups" { default = []               }

###################################################################################################

variable "worker_role_arns"             { default = []            }
variable "cluster_log_types"            { default = []            }
variable "kubernetes_version"           { default = "1.18"        }
variable "cluster_log_retention"        { default = 30            }
variable "cluster_admin_role_arns"      { default = []            }
variable "kms_key_deletion_window"      { default = 7             }
variable "encrypted_cluster_resources"  { default = [ "secrets" ] }

###################################################################################################

variable "cost_center"                  { default = "None"          }
variable "owner_contact"                { default = "Platform Team" }

###################################################################################################