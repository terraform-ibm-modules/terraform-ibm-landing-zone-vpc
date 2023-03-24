##############################################################################
# VPC GUID
##############################################################################

output "vpc_name" {
  description = "Name of VPC created"
  value       = ibm_is_vpc.vpc.name
}

output "vpc_id" {
  description = "ID of VPC created"
  value       = ibm_is_vpc.vpc.id
}

output "vpc_crn" {
  description = "CRN of VPC created"
  value       = ibm_is_vpc.vpc.crn
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
    for subnet in ibm_is_subnet.subnet :
    subnet.id
  ]
}

output "subnet_detail_list" {
  description = "A list of subnets containing names, CIDR blocks, and zones."
  value = {
    for zone_name in distinct([
      for subnet in ibm_is_subnet.subnet :
      subnet.zone
    ]) :
    zone_name => {
      for subnet in ibm_is_subnet.subnet :
      subnet.name => {
        id   = subnet.id
        cidr = subnet.ipv4_cidr_block
      } if subnet.zone == zone_name
    }
  }
}

output "subnet_zone_list" {
  description = "A list containing subnet IDs and subnet zones"
  value = [
    for subnet in ibm_is_subnet.subnet : {
      name = subnet.name
      id   = subnet.id
      zone = subnet.zone
      cidr = subnet.ipv4_cidr_block
    }
  ]
}

output "subnet_detail_map" {
  description = "A map of subnets containing IDs, CIDR blocks, and zones"
  value = {
    for zone_name in distinct([
      for subnet in ibm_is_subnet.subnet :
      subnet.zone
    ]) :
    "zone-${substr(zone_name, -1, length(zone_name))}" => [
      for subnet in ibm_is_subnet.subnet :
      {
        id         = subnet.id
        zone       = subnet.zone
        cidr_block = subnet.ipv4_cidr_block
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
    }
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
