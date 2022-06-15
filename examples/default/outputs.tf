##############################################################################
# Outputs
##############################################################################

output "id" {
  value       = module.deploy_vpc.vpc_id
  description = "VPC id"
}

output "crn" {
  value       = module.deploy_vpc.vpc_crn
  description = "VPC crn"
}
