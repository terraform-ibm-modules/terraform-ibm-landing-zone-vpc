##############################################################################
# VPC
##############################################################################

output "vpc_name" {
  description = "Name of VPC created"
  value       = module.vpc.vpc_name
}

output "vpc_id" {
  description = "ID of VPC created"
  value       = module.vpc.vpc_id
}

output "vpc_crn" {
  description = "CRN of VPC created"
  value       = module.vpc.vpc_crn
}

##############################################################################
# Public Gateways
##############################################################################

output "public_gateways" {
  description = "Map of public gateways by zone"
  value       = module.vpc.public_gateways
}

##############################################################################
# VPC flow logs
##############################################################################

output "vpc_flow_logs" {
  description = "Details of VPC flow logs collector"
  value       = module.vpc.vpc_flow_logs
}

##############################################################################
# Network ACLs
##############################################################################

output "network_acls" {
  description = "List of shortnames and IDs of network ACLs"
  value       = module.vpc.network_acls
}

##############################################################################
# Subnet Outputs
##############################################################################

output "subnet_ids" {
  description = "The IDs of the subnets"
  value       = module.vpc.subnet_ids
}

output "subnet_detail_list" {
  description = "A list of subnets containing names, CIDR blocks, and zones."
  value       = module.vpc.subnet_detail_list
}

output "subnet_zone_list" {
  description = "A list containing subnet IDs and subnet zones"
  value       = module.vpc.subnet_zone_list
}

output "subnet_detail_map" {
  description = "A map of subnets containing IDs, CIDR blocks, and zones"
  value       = module.vpc.subnet_detail_map
}
