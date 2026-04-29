##############################################################################
# Outputs
##############################################################################

# VPC Outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = module.ibm_vpc.vpc_id
}

output "vpc_name" {
  description = "Name of the VPC"
  value       = module.ibm_vpc.vpc_name
}

output "vpc_crn" {
  description = "CRN of the VPC"
  value       = module.ibm_vpc.vpc_crn
}

output "subnet_ids" {
  description = "IDs of the subnets"
  value       = module.ibm_vpc.subnet_ids
}

output "subnet_zone_list" {
  description = "List of subnet IDs by zone"
  value       = module.ibm_vpc.subnet_zone_list
}

# COS Outputs
output "cos_instance_id" {
  description = "ID of the COS instance"
  value       = module.cos.cos_instance_id
}

output "cos_instance_guid" {
  description = "GUID of the COS instance"
  value       = module.cos.cos_instance_guid
}

output "cos_bucket_name" {
  description = "Name of the COS bucket"
  value       = module.cos.bucket_name
}

output "cos_bucket_id" {
  description = "ID of the COS bucket"
  value       = module.cos.bucket_id
}

# Flow Logs Outputs
output "vpc_flow_logs" {
  description = "VPC flow logs collector information"
  value       = module.ibm_vpc.vpc_flow_logs
}
