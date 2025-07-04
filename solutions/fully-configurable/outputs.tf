##############################################################################
# VPC
##############################################################################

output "vpc_name" {
  description = "Name of the VPC created."
  value       = module.vpc.vpc_name
}

output "vpc_id" {
  description = "ID of the VPC created."
  value       = module.vpc.vpc_id
}

output "vpc_crn" {
  description = "CRN of the VPC created."
  value       = module.vpc.vpc_crn
}

##############################################################################
# Public Gateways
##############################################################################

output "public_gateways" {
  description = "Map of the public gateways by zone."
  value       = module.vpc.public_gateways
}

##############################################################################
# VPC flow logs
##############################################################################

output "vpc_flow_logs" {
  description = "Details of the VPC flow logs collector."
  value       = module.vpc.vpc_flow_logs
}

##############################################################################
# Network ACLs
##############################################################################

output "network_acls" {
  description = "List of shortnames and IDs of network ACLs."
  value       = module.vpc.network_acls
}

##############################################################################
# Subnet Outputs
##############################################################################

output "subnet_ids" {
  description = "The IDs of the subnets."
  value       = module.vpc.subnet_ids
}

output "private_path_subnet_id" {
  description = "The IDs of the subnets."
  value       = length(module.vpc.subnet_ids) > 0 ? module.vpc.subnet_ids[0] : null
}

output "subnet_detail_list" {
  description = "A list of subnets containing names, CIDR blocks, and zones."
  value       = module.vpc.subnet_detail_list
}

output "subnet_zone_list" {
  description = "A list of subnet IDs and subnet zones."
  value       = module.vpc.subnet_zone_list
}

output "subnet_detail_map" {
  description = "A map of subnets containing IDs, CIDR blocks, and zones."
  value       = module.vpc.subnet_detail_map
}

##############################################################################
# VPN Gateways Outputs
##############################################################################

output "vpn_gateways_name" {
  description = "List of names of VPN gateways."
  value       = module.vpc.vpn_gateways_name
}

output "vpn_gateways_data" {
  description = "Details of VPN gateways data."
  value       = module.vpc.vpn_gateways_data
}

##############################################################################
# VPE Outputs
##############################################################################

output "vpe_ips" {
  description = "The reserved IPs for endpoint gateways."
  value       = module.vpe_gateway.vpe_ips
}

output "vpe_crn" {
  description = "The CRN of the endpoint gateway."
  value       = module.vpe_gateway.crn
}

##############################################################################
# Security Group Details
##############################################################################

output "security_group_details" {
  description = "Details of security group."
  value       = module.vpc.security_group_details
}
