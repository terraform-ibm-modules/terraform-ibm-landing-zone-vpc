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
