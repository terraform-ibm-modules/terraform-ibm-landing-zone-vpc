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

output "custom_resolver_hub" {
  value       = module.hub_vpc.custom_resolver_hub
  description = "The custom resolver created for the hub vpc."
}

output "dns_endpoint_gateways_spoke_vpc_crn" {
  value       = module.spoke_vpc.dns_endpoint_gateways_crn
  description = "The endpoint gateways in the bound to VPC that are allowed to participate in this DNS resolution binding."
}

output "dns_endpoint_gateways_spoke_vpc_id" {
  value       = module.spoke_vpc.dns_endpoint_gateways_id
  description = "The endpoint gateways in the bound to VPC that are allowed to participate in this DNS resolution binding."
}
