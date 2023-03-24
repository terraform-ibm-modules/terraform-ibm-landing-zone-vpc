##############################################################################
# Outputs
##############################################################################

output "vpc_name" {
  description = "VPC name"
  value       = module.workload_vpc.vpc_name
}

output "vpc_id" {
  description = "ID of VPC created"
  value       = module.workload_vpc.vpc_id
}

output "vpc_crn" {
  description = "CRN of VPC created"
  value       = module.workload_vpc.vpc_crn
}
