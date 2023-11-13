##############################################################################
# Outputs
##############################################################################

output "hub_vpc_id" {
  value       = module.hub_vpc.vpc_id
  description = "Hub VPC id"
}

output "hub_vpc_crn" {
  value       = module.hub_vpc.vpc_crn
  description = "Hub VPC crn"
}

output "spoke_vpc_id" {
  value       = module.spoke_vpc.vpc_id
  description = "Hub VPC id"
}

output "spoke_vpc_crn" {
  value       = module.spoke_vpc.vpc_crn
  description = "Hub VPC crn"
}
