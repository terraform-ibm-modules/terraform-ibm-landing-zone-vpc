##############################################################################
# Outputs
##############################################################################

output "vpc_id" {
  value       = module.slz_vpc.vpc_id
  description = "VPC id"
}

output "vpc_crn" {
  value       = module.slz_vpc.vpc_crn
  description = "VPC crn"
}

output "vpc_flow_logs_collector" {
  value       = module.slz_vpc.vpc_flow_logs
  description = "VPC flow logs collector"
}

output "cos_instance_crn" {
  value       = ibm_resource_instance.cos_instance[0].crn
  description = "COS instance crn"
}

output "cos_bucket_name" {
  value       = ibm_cos_bucket.cos_bucket[0].bucket_name
  description = "COS bucket name"
}
