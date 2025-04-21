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

output "transit_gateway_id" {
  value       = module.tg_gateway_connection.tg_id
  description = "The ID of the transit gateway"
}

output "transit_gateway_crn" {
  value       = module.tg_gateway_connection.tg_crn
  description = "The CRN of the transit gateway"
}

output "vpc_connection_ids" {
  value       = module.tg_gateway_connection.vpc_conn_ids
  description = "List of VPC connection IDs."
}

output "custom_resolver_hub_vpc" {
  value       = module.hub_vpc.custom_resolver_hub
  description = "The custom resolver created for the hub vpc."
}

output "dns_endpoint_gateways_by_spoke_vpc_crn" {
  value       = module.spoke_vpc.dns_endpoint_gateways_by_crn
  description = "The list of VPEs that are made available for DNS resolution in the created VPC."
}

output "dns_endpoint_gateways_by_spoke_vpc_id" {
  value       = module.spoke_vpc.dns_endpoint_gateways_by_id
  description = "The list of VPEs that are made available for DNS resolution in the created VPC."
}

output "dns_instance_id" {
  description = "The ID of the DNS instance."
  value       = module.hub_vpc.dns_instance_id
}

output "dns_custom_resolver_ids" {
  description = "The list of DNS Custom Resolver IDs used"
  value       = module.hub_vpc.dns_custom_resolver_ids
}
