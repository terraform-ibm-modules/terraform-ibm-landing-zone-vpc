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
