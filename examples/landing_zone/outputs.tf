##############################################################################
# Outputs
##############################################################################

output "workload_vpc_name" {
  description = "VPC name"
  value       = module.workload_vpc.vpc_name
}

output "workload_vpc_id" {
  description = "ID of VPC created"
  value       = module.workload_vpc.vpc_id
}

output "workload_vpc_crn" {
  description = "CRN of VPC created"
  value       = module.workload_vpc.vpc_crn
}

output "management_vpc_name" {
  description = "VPC name"
  value       = module.management_vpc.vpc_name
}

output "management_vpc_id" {
  description = "ID of VPC created"
  value       = module.management_vpc.vpc_id
}

output "management_vpc_crn" {
  description = "CRN of VPC created"
  value       = module.management_vpc.vpc_crn
}

output "sample" {
  value = module.workload_vpc.sample
}