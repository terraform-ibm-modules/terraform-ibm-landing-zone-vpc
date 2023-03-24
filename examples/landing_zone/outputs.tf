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

output "cos_instance_crn" {
  value       = ibm_resource_instance.cos_instance[0].crn
  description = "COS instance crn"
}

output "cos_bucket_name" {
  value       = ibm_cos_bucket.cos_bucket[0].bucket_name
  description = "COS bucket name"
}
