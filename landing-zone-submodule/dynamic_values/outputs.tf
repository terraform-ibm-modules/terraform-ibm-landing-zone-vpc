# ##############################################################################
# # Outputs
# ##############################################################################

##############################################################################
# Resource Group Outputs
##############################################################################

output "resource_groups" {
  description = "List of resource groups transformed to use as landing zone configuration"
  value       = local.resource_groups
}

##############################################################################


##############################################################################
# VPC Value Outputs
##############################################################################

output "vpc_list" {
  description = "List of VPCs, used for adding Edge VPC"
  value       = local.vpc_list
}

output "vpcs" {
  description = "List of VPCs with needed information to be created by landing zone module"
  value       = local.vpcs
}
