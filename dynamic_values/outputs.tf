
##############################################################################
# Address Prefix Outputs
##############################################################################

output "address_prefixes" {
  description = "Address prefix list"
  value       = local.address_prefixes
}

##############################################################################

##############################################################################
# Routes Outputs
##############################################################################

output "routes" {
  description = "Routes map"
  value       = local.routes_map
}

##############################################################################

##############################################################################
# Public Gateways Outputs
##############################################################################

output "use_public_gateways" {
  description = "Public gateways map"
  value       = local.gateway_map
}

##############################################################################

##############################################################################
# Security Group Rules Outputs
##############################################################################

output "security_group_rules" {
  description = "Security Group Rules map"
  value       = local.security_group_rule_object
}

##############################################################################

##############################################################################
# Cluster Rules
##############################################################################

output "cluster_rules" {
  description = "Cluster creation ACL allow rules"
  value       = local.cluster_rules
}

##############################################################################

##############################################################################
# ACLs
##############################################################################

output "acl_map" {
  description = "ACL map"
  value       = local.acl_map
}

##############################################################################

##############################################################################
# Subnets
##############################################################################

output "subnet_list" {
  description = "Subnet list"
  value       = local.subnet_list
}

output "subnet_map" {
  description = "Subnets as map"
  value       = local.subnet_map
}

##############################################################################
