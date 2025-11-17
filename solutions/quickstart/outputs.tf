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
# Security Group Details
##############################################################################

output "security_group_details" {
  description = "Details of security group."
  value       = module.vpc.security_group_details
}

output "next_steps_text" {
  value       = "Your Virtual Private Cloud is ready."
  description = "Next steps text"
}

output "next_step_primary_label" {
  value       = "Go to Virtual Private Cloud"
  description = "Primary label"
}

output "next_step_primary_url" {
  value       = "https://cloud.ibm.com/infrastructure/network/vpc/${var.region}~${module.vpc.vpc_id}/overview"
  description = "Primary URL"
}

output "next_step_secondary_label" {
  value       = "Virtual Private Cloud overview page"
  description = "Secondary label"
}

output "next_step_secondary_url" {
  value       = "https://cloud.ibm.com/docs/vpc?topic=vpc-about-vpc"
  description = "Secondary URL"
}
