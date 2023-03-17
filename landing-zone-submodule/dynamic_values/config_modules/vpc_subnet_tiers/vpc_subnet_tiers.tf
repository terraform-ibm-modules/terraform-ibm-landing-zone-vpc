##############################################################################
# Variables
##############################################################################

variable "vpcs" {
  description = "List of VPCs to create. The first VPC in this list will always be considered the `management` VPC, and will be where the VPN Gateway is connected. VPCs names can only be a maximum of 16 characters and can only contain letters, numbers, and - characters. VPC names must begin with a letter.. The first VPC in this list will always be considered the `management` VPC, and will be where the VPN Gateway is connected. VPCs names can only be a maximum of 16 characters and can only contain letters, numbers, and - characters. VPC names must begin with a letter."
  type        = list(string)

  validation {
    error_message = "VPCs names can only be a maximum of 16 characters and can only contain letters, numbers, and - characters. Names must also begin with a letter and end with a letter or number."
    condition = length([
      for name in var.vpcs :
      name if length(name) > 16 || !can(regex("^([A-z]|[a-z][-a-z0-9]*[a-z0-9])$", name))
    ]) == 0
  }
}

variable "vpc_list" {
  description = "List of VPCs"
  type        = list(string)
}

##############################################################################

##############################################################################
# Locals
##############################################################################

locals {
  vpc_subnet_tiers = {
    for network in var.vpc_list :
    (network) => {
      zone-1 = (
         ["vsi", "vpe"]
      )
      zone-2 = (
         ["vsi", "vpe"]
      )
      zone-3 = (
         ["vsi", "vpe"]
      )
    }
  }
}

##############################################################################

##############################################################################
# Outputs
##############################################################################

output "value" {
  description = "Map of networks and corresponding subnet tiers"
  value       = local.vpc_subnet_tiers
}

##############################################################################
