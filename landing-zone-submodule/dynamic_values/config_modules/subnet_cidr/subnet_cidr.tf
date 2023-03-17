##############################################################################
# Variables
##############################################################################

variable "network" {
  description = "Name of network"
  type        = string
}

variable "vpc_list" {
  description = "List of VPCs"
  type        = list(string)
}

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

variable "subnet_tiers" {
  description = "Zone to subnet tier map for a VPC"
  type = object({
    zone-1 = list(string)
    zone-2 = list(string)
    zone-3 = list(string)
  })
}

##############################################################################

##############################################################################
# Outputs
##############################################################################

output "value" {
  description = "Map of subnet cidr by zone"
  value = {
    for zone in [1, 2, 3] :
    "zone-${zone}" => {
      for tier in var.subnet_tiers["zone-${zone}"] :
      (tier) => 
       "10.${zone + (index(var.vpcs, var.network) * 3)}0.${1 + index(["vsi", "vpe", "vpn", "bastion"], tier)}0.0/24"
    }
  }
}

##############################################################################
