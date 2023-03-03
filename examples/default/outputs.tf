##############################################################################
# Outputs
##############################################################################

output "id" {
  value       = module.slz_vpc.vpc_id
  description = "VPC id"
}

output "crn" {
  value       = module.slz_vpc.vpc_crn
  description = "VPC crn"
}

output "vpc_flow_logs" {
  value       = module.slz_vpc.vpc_flow_logs
  description = "VPC flow logs collector"
}
