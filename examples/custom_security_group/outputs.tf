##############################################################################
# Outputs
##############################################################################

output "vpc_id" {
  value       = module.vpc.vpc_id
  description = "VPC id"
}

output "vpc_crn" {
  value       = module.vpc.vpc_crn
  description = "VPC crn"
}
