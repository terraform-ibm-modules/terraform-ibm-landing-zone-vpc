##############################################################################
# VPC GUID
##############################################################################

output "vpc_name" {
  description = "Name of VPC created"
  value       = local.vpc_name
}

output "vpc_id" {
  description = "ID of VPC created"
  value       = local.vpc_id
}

output "vpc_crn" {
  description = "CRN of VPC created"
  value       = local.vpc_crn
}

##############################################################################

##############################################################################
# Public Gateways
##############################################################################

output "public_gateways" {
  description = "Map of public gateways by zone"
  value = {
    for zone in [1, 2, 3] :
    "zone-${zone}" => (
      var.use_public_gateways["zone-${zone}"] == false
      ? null
      : ibm_is_public_gateway.gateway["zone-${zone}"].id
    )
  }
}

##############################################################################

##############################################################################
# Subnet Outputs
##############################################################################

output "subnet_ids" {
  description = "The IDs of the subnets"
  value = [
    for subnet in local.subnets :
    subnet.id
  ]
}

output "subnet_detail_list" {
  description = "A list of subnets containing names, CIDR blocks, and zones."
  value = {
    for zone_name in distinct([
      for subnet in local.subnets :
      subnet.zone
    ]) :
    zone_name => {
      for subnet in local.subnets :
      subnet.name => {
        id   = subnet.id
        cidr = subnet.ipv4_cidr_block
        crn  = subnet.crn
      } if subnet.zone == zone_name
    }
  }
}

output "subnet_zone_list" {
  description = "A list containing subnet IDs and subnet zones"
  value = [
    for subnet in local.subnets : {
      name = subnet.name
      id   = subnet.id
      zone = subnet.zone
      cidr = subnet.ipv4_cidr_block
      crn  = subnet.crn
    }
  ]
}

output "subnet_detail_map" {
  description = "A map of subnets containing IDs, CIDR blocks, and zones"
  value = {
    for zone_name in distinct([
      for subnet in local.subnets :
      subnet.zone
    ]) :
    "zone-${substr(zone_name, -1, length(zone_name))}" => [
      for subnet in local.subnets :
      {
        id         = subnet.id
        zone       = subnet.zone
        cidr_block = subnet.ipv4_cidr_block
        crn        = subnet.crn
      } if subnet.zone == zone_name
    ]
  }
}

##############################################################################

##############################################################################
# Network ACLs
##############################################################################

output "network_acls" {
  description = "List of shortnames and IDs of network ACLs"
  value = [
    for network_acl in local.acl_object :
    {
      shortname = network_acl.name
      id        = ibm_is_network_acl.network_acl[network_acl.name].id
    } if var.create_subnets
  ]
}

##############################################################################

##############################################################################
# VPC flow logs
##############################################################################

output "vpc_flow_logs" {
  description = "Details of VPC flow logs collector"
  value = var.enable_vpc_flow_logs != true ? [] : [
    for flow_log_collector in ibm_is_flow_log.flow_logs :
    {
      name  = flow_log_collector.name
      id    = flow_log_collector.id
      crn   = flow_log_collector.crn
      href  = flow_log_collector.href
      state = flow_log_collector.lifecycle_state
    }
  ]
}

##############################################################################

output "cidr_blocks" {
  description = "List of CIDR blocks present in VPC stack"
  value       = [for address in data.ibm_is_vpc_address_prefixes.get_address_prefixes.address_prefixes : address.cidr]
}

output "vpc_data" {
  description = "Data of the VPC used in this module, created or existing."
  value       = data.ibm_is_vpc.vpc
}

##############################################################################
# Hub and Spoke specific configuration
##############################################################################

output "custom_resolver_hub" {
  description = "The custom resolver created for the hub vpc. Only set if enable_hub is set and skip_custom_resolver_hub_creation is false."
  value       = length(ibm_dns_custom_resolver.custom_resolver_hub) == 1 ? ibm_dns_custom_resolver.custom_resolver_hub[0] : null
}

output "dns_endpoint_gateways_by_id" {
  description = "The list of VPEs that are made available for DNS resolution in the created VPC. Only set if enable_hub is false and enable_hub_vpc_id are true."
  value       = length(ibm_is_vpc_dns_resolution_binding.vpc_dns_resolution_binding_id) == 1 ? ibm_is_vpc_dns_resolution_binding.vpc_dns_resolution_binding_id[0] : null
}

output "dns_endpoint_gateways_by_crn" {
  description = "The list of VPEs that are made available for DNS resolution in the created VPC. Only set if enable_hub is false and enable_hub_vpc_id are true."
  value       = length(ibm_is_vpc_dns_resolution_binding.vpc_dns_resolution_binding_crn) == 1 ? ibm_is_vpc_dns_resolution_binding.vpc_dns_resolution_binding_crn[0] : null
}

output "dns_instance_id" {
  description = "The ID of the DNS instance."
  value       = (var.enable_hub && !var.skip_custom_resolver_hub_creation) ? (var.use_existing_dns_instance ? var.existing_dns_instance_id : ibm_resource_instance.dns_instance_hub[0].guid) : null
}

output "dns_custom_resolver_id" {
  description = "The ID of the DNS Custom Resolver."
  value       = (var.enable_hub && !var.skip_custom_resolver_hub_creation) ? one(ibm_dns_custom_resolver.custom_resolver_hub[*].instance_id) : null
}

## DNS Zone and Records
output "dns_zone_state" {
  description = "The state of the DNS zone."
  value       = length(ibm_dns_zone.dns_zone) > 0 ? ibm_dns_zone.dns_zone[0].state : null
}

output "dns_zone" {
  description = "The ID of the DNS zone. The ID is composed of <instance_id>/<zone_id>"
  value       = length(ibm_dns_zone.dns_zone) > 0 ? ibm_dns_zone.dns_zone[0].id : null
}

output "dns_zone_id" {
  description = "The ID of the zone that is associated with the DNS zone."
  value       = length(ibm_dns_zone.dns_zone) > 0 ? ibm_dns_zone.dns_zone[0].zone_id : null
}

output "dns_record_ids" {
  description = "List of all the domain resource records."
  value       = [for record in ibm_dns_resource_record.dns_record : record.id]
}
