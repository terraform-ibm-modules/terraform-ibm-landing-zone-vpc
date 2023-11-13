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

output "transit_gateway_crn" {
  value       = module.tg_gateway_connection.tg_crn
  description = "The CRN of the transit gateway"
}

output "custom_resolver_hub_vpc" {
  description = "The custom resolver created for the hub vpc. Only set if enable_hub is set and skip_custom_resolver_hub_creation is false."
  value       = module.hub_vpc.custom_resolver_hub
}

output "dns_endpoint_gateways_spoke_vpc_crn" {
  value       = module.spoke_vpc.dns_endpoint_gateways_crn
  description = "The endpoint gateways in the bound to VPC that are allowed to participate in this DNS resolution binding."
}

output "dns_endpoint_gateways_spoke_vpc_id" {
  value       = module.spoke_vpc.dns_endpoint_gateways_id
  description = "The endpoint gateways in the bound to VPC that are allowed to participate in this DNS resolution binding."
}
