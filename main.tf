##############################################################################
# terraform-ibm-landing-zone-vpc


##############################################################################
# Check if existing vpc id is passed
##############################################################################

data "ibm_is_vpc" "vpc" {
  depends_on = [time_sleep.wait_for_vpc_creation_data]
  identifier = local.vpc_id
}

locals {
  vpc_id   = var.create_vpc ? resource.ibm_is_vpc.vpc[0].id : var.existing_vpc_id
  vpc_name = var.create_vpc ? resource.ibm_is_vpc.vpc[0].name : data.ibm_is_vpc.vpc.name
  vpc_crn  = var.create_vpc ? resource.ibm_is_vpc.vpc[0].crn : data.ibm_is_vpc.vpc.crn
}

##############################################################################
# Create new VPC
##############################################################################

resource "time_sleep" "wait_for_vpc_creation_data" {
  depends_on      = [resource.ibm_is_vpc.vpc, resource.ibm_is_subnet.subnet]
  count           = var.create_vpc == true || var.create_subnets ? 1 : 0
  create_duration = "30s"
}

resource "ibm_is_vpc" "vpc" {
  count          = var.create_vpc == true ? 1 : 0
  name           = var.prefix != null ? "${var.prefix}-${var.name}" : var.name
  resource_group = var.resource_group_id
  # address prefix is set to auto only if no address prefixes NOR any subnet is passed as input
  address_prefix_management   = (length([for prefix in values(coalesce(var.address_prefixes, {})) : prefix if prefix != null]) != 0) || (length([for subnet in values(coalesce(var.subnets, {})) : subnet if subnet != null]) != 0) ? "manual" : null
  default_network_acl_name    = var.default_network_acl_name
  default_security_group_name = var.default_security_group_name
  default_routing_table_name  = var.default_routing_table_name
  tags                        = var.tags
  access_tags                 = var.access_tags
  no_sg_acl_rules             = var.clean_default_sg_acl

  dns {
    enable_hub = var.enable_hub

    # Delegated resolver
    dynamic "resolver" {
      for_each = (var.enable_hub_vpc_id || var.enable_hub_vpc_crn) && var.update_delegated_resolver && var.resolver_type == "delegated" ? [1] : []
      content {
        type    = "delegated"
        vpc_id  = var.hub_vpc_id != null ? var.hub_vpc_id : null
        vpc_crn = var.hub_vpc_crn != null ? var.hub_vpc_crn : null
        dns_binding_name = coalesce(
          var.dns_binding_name,
          "${var.prefix != null ? "${var.prefix}-${var.name}" : var.name}-dns-binding"
        )
      }
    }

    # Manual resolver
    dynamic "resolver" {
      for_each = var.resolver_type == "manual" && !var.update_delegated_resolver ? [1] : []
      content {
        type = var.resolver_type
        dynamic "manual_servers" {
          for_each = length(var.manual_servers) > 0 ? var.manual_servers : []
          content {
            address       = manual_servers.value.address
            zone_affinity = manual_servers.value.zone_affinity
          }
        }
      }
    }

    # System resolver
    dynamic "resolver" {
      for_each = var.resolver_type == "system" && !var.update_delegated_resolver ? [1] : []
      content {
        type = var.resolver_type
      }
    }
  }

  lifecycle {
    precondition {
      condition     = var.resource_group_id != null
      error_message = "Resource Group ID must not be null."
    }
    postcondition {
      condition     = self.status == "available"
      error_message = "VPC status is ${self.status}, expected available."
    }
  }
}

data "ibm_is_vpc_dns_resolution_bindings" "dns_bindings" {
  count  = (!var.enable_hub && (var.enable_hub_vpc_id || var.enable_hub_vpc_crn)) ? 1 : 0
  vpc_id = local.vpc_id
}

###############################################################################

##############################################################################
# Hub and Spoke specific configuration
# See https://cloud.ibm.com/docs/vpc?topic=vpc-hub-spoke-model for context
##############################################################################

# fetch this account ID
data "ibm_iam_account_settings" "iam_account_settings" {}

# spoke -> hub auth policy based on https://cloud.ibm.com/docs/vpc?topic=vpc-vpe-dns-sharing-s2s-auth&interface=terraform
resource "ibm_iam_authorization_policy" "vpc_dns_resolution_auth_policy" {
  count = (var.enable_hub == false && var.skip_spoke_auth_policy == false && (var.enable_hub_vpc_id || var.enable_hub_vpc_crn)) ? 1 : 0
  roles = ["DNS Binding Connector"]
  # subject is the spoke
  subject_attributes {
    name  = "accountId"
    value = data.ibm_iam_account_settings.iam_account_settings.account_id
  }
  subject_attributes {
    name  = "serviceName"
    value = "is"
  }
  subject_attributes {
    name  = "resourceType"
    value = "vpc"
  }
  subject_attributes {
    name  = "resource"
    value = local.vpc_id
  }
  # resource is the hub
  resource_attributes {
    name  = "accountId"
    value = var.hub_account_id
  }
  resource_attributes {
    name  = "serviceName"
    value = "is"
  }
  resource_attributes {
    name  = "vpcId"
    value = var.enable_hub_vpc_id ? var.hub_vpc_id : split(":", var.hub_vpc_crn)[9]
  }
}

# Set up separate DNS resolution binding in case the resolver type is NOT delegated.
resource "ibm_is_vpc_dns_resolution_binding" "vpc_dns_resolution_binding_id" {
  count = (var.enable_hub == false && var.enable_hub_vpc_id) && var.resolver_type != "delegated" ? 1 : 0
  # Depends on required as the authorization policy cannot be directly referenced
  depends_on = [ibm_iam_authorization_policy.vpc_dns_resolution_auth_policy]

  # Use var.dns_binding_name if not null, otherwise, use var.prefix and var.name combination.
  name = coalesce(
    var.dns_binding_name,
    "${var.prefix != null ? "${var.prefix}-${var.name}" : var.name}-dns-binding"
  )
  vpc_id = local.vpc_id # Source VPC
  vpc {
    id = var.hub_vpc_id # Target VPC ID
  }
}

# Set up separate DNS resolution binding in case the resolver type is NOT delegated.
resource "ibm_is_vpc_dns_resolution_binding" "vpc_dns_resolution_binding_crn" {
  count = (var.enable_hub == false && var.enable_hub_vpc_crn) && var.resolver_type != "delegated" ? 1 : 0
  # Depends on required as the authorization policy cannot be directly referenced
  depends_on = [ibm_iam_authorization_policy.vpc_dns_resolution_auth_policy]

  # Use var.dns_binding_name if not null, otherwise, use var.prefix and var.name combination.
  name = coalesce(
    var.dns_binding_name,
    "${var.prefix != null ? "${var.prefix}-${var.name}" : var.name}-dns-binding"
  )
  vpc_id = local.vpc_id # Source VPC
  vpc {
    crn = var.hub_vpc_crn # Target VPC CRN
  }
}

# Configure custom resolver on the hub vpc
resource "ibm_resource_instance" "dns_instance_hub" {
  count = var.enable_hub && !var.skip_custom_resolver_hub_creation && !var.use_existing_dns_instance ? 1 : 0

  # Use var.dns_instance_name if not null, otherwise, use var.prefix and var.name combination.
  name = coalesce(
    var.dns_instance_name,
    "${var.prefix != null ? "${var.prefix}-${var.name}" : var.name}-dns-instance"
  )
  resource_group_id = var.resource_group_id
  location          = var.dns_location
  service           = "dns-svcs"
  plan              = var.dns_plan
}

resource "ibm_dns_custom_resolver" "custom_resolver_hub" {
  count = var.enable_hub && !var.skip_custom_resolver_hub_creation ? 1 : 0

  # Use var.dns_custom_resolver_name if not null, otherwise, use var.prefix and var.name combination.
  name = coalesce(
    var.dns_custom_resolver_name,
    "${var.prefix != null ? "${var.prefix}-${var.name}" : var.name}-custom-resolver"
  )
  instance_id       = var.use_existing_dns_instance ? var.existing_dns_instance_id : ibm_resource_instance.dns_instance_hub[0].guid
  high_availability = true
  enabled           = true

  dynamic "locations" {
    for_each = local.subnets
    content {
      subnet_crn = locations.value.crn
      enabled    = true
    }
  }
}

##############################################################################


##############################################################################
# Address Prefixes
##############################################################################

locals {
  # For each address prefix
  address_prefixes = {
    for prefix in module.dynamic_values.address_prefixes :
    (prefix.name) => prefix
  }
}

resource "ibm_is_vpc_address_prefix" "address_prefixes" {
  for_each = local.address_prefixes
  name     = each.value.name
  vpc      = local.vpc_id
  zone     = each.value.zone
  cidr     = each.value.cidr
}

data "ibm_is_vpc_address_prefixes" "get_address_prefixes" {
  depends_on = [ibm_is_vpc_address_prefix.address_prefixes, ibm_is_vpc_address_prefix.subnet_prefix]
  vpc        = local.vpc_id
}
##############################################################################

# workaround for https://github.com/IBM-Cloud/terraform-provider-ibm/issues/4478
resource "time_sleep" "wait_for_authorization_policy" {
  depends_on      = [ibm_iam_authorization_policy.policy]
  count           = (var.enable_vpc_flow_logs) ? ((var.create_authorization_policy_vpc_to_cos) ? 1 : 0) : 0
  create_duration = "30s"
}

##############################################################################
# Create vpc route resource
##############################################################################

resource "ibm_is_vpc_routing_table" "route_table" {
  for_each = module.dynamic_values.routing_table_map
  # Use var.routing_table_name if not null, otherwise, use var.prefix and var.name combination.
  name                          = var.routing_table_name != null ? "${var.routing_table_name}-${each.value.name}" : var.prefix != null ? "${var.prefix}-${var.name}-route-${each.value.name}" : "${var.name}-route-${each.value.name}"
  vpc                           = local.vpc_id
  route_direct_link_ingress     = each.value.route_direct_link_ingress
  route_transit_gateway_ingress = each.value.route_transit_gateway_ingress
  route_vpc_zone_ingress        = each.value.route_vpc_zone_ingress
}

resource "ibm_is_vpc_routing_table_route" "routing_table_routes" {
  for_each      = module.dynamic_values.routing_table_route_map
  vpc           = local.vpc_id
  routing_table = ibm_is_vpc_routing_table.route_table[each.value.route_table].routing_table
  zone          = "${var.region}-${each.value.zone}"
  name          = each.key
  destination   = each.value.destination
  action        = each.value.action
  next_hop      = each.value.next_hop
}

##############################################################################


##############################################################################
# Public Gateways (Optional)
##############################################################################

locals {
  # create object that only contains gateways that will be created
  gateway_object = {
    for zone in keys(var.use_public_gateways) :
    zone => "${var.region}-${index(keys(var.use_public_gateways), zone) + 1}" if var.use_public_gateways[zone]
  }
}

resource "ibm_is_public_gateway" "gateway" {
  for_each = local.gateway_object
  # Use var.public_gateway_name if not null, otherwise, use var.prefix and var.name combination.
  name           = var.public_gateway_name != null ? "${var.public_gateway_name}-${each.key}" : var.prefix != null ? "${var.prefix}-${var.name}-public-gateway-${each.key}" : "${var.name}-public-gateway-${each.key}"
  vpc            = local.vpc_id
  resource_group = var.resource_group_id
  zone           = each.value
  tags           = var.tags
  access_tags    = var.access_tags

  lifecycle {
    postcondition {
      condition     = self.status == "available"
      error_message = "Public Gateway status is ${self.status}, expected available."
    }
  }
}

##############################################################################

##############################################################################
# Add VPC to Flow Logs
##############################################################################

# Create authorization policy to allow VPC to access COS Bucket
resource "ibm_iam_authorization_policy" "policy" {
  count = (var.enable_vpc_flow_logs) ? ((var.create_authorization_policy_vpc_to_cos) ? 1 : 0) : 0

  source_service_name  = "is"
  source_resource_type = "flow-log-collector"
  roles                = ["Writer"]

  resource_attributes {
    name     = "accountId"
    operator = "stringEquals"
    value    = data.ibm_iam_account_settings.iam_account_settings.account_id
  }

  resource_attributes {
    name     = "serviceName"
    operator = "stringEquals"
    value    = "cloud-object-storage"
  }

  resource_attributes {
    name     = "serviceInstance"
    operator = "stringEquals"
    value    = var.existing_cos_instance_guid
  }

  resource_attributes {
    name     = "resourceType"
    operator = "stringEquals"
    value    = "bucket"
  }

  resource_attributes {
    name     = "resource"
    operator = "stringEquals"
    value    = var.existing_storage_bucket_name
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Create VPC flow logs collector
resource "ibm_is_flow_log" "flow_logs" {
  count = (var.enable_vpc_flow_logs) ? 1 : 0

  # Use var.vpc_flow_logs_name if not null, otherwise, use var.prefix and var.name combination.
  name = coalesce(
    var.vpc_flow_logs_name,
    "${var.prefix != null ? "${var.prefix}-${var.name}" : var.name}-logs"
  )
  target         = local.vpc_id
  active         = var.is_flow_log_collector_active
  storage_bucket = var.existing_storage_bucket_name
  resource_group = var.resource_group_id
  tags           = var.tags
  access_tags    = var.access_tags
}

##############################################################################
# DNS ZONE
###############################################################################

resource "ibm_dns_zone" "dns_zone" {
  for_each    = var.enable_hub && !var.skip_custom_resolver_hub_creation ? { for zone in var.dns_zones : zone.name => zone } : {}
  name        = each.key
  instance_id = var.use_existing_dns_instance ? var.existing_dns_instance_id : ibm_resource_instance.dns_instance_hub[0].guid
  description = each.value.description == null ? "Hosted zone for ${each.key}" : each.value.description
  label       = each.value.label
}

##############################################################################
# DNS PERMITTED NETWORK
##############################################################################

resource "ibm_dns_permitted_network" "dns_permitted_network" {
  for_each    = var.enable_hub && !var.skip_custom_resolver_hub_creation ? ibm_dns_zone.dns_zone : {}
  instance_id = var.use_existing_dns_instance ? var.existing_dns_instance_id : ibm_resource_instance.dns_instance_hub[0].guid
  zone_id     = each.value.zone_id
  vpc_crn     = local.vpc_crn
  type        = "vpc"
}

##############################################################################
# DNS Records
##############################################################################

locals {
  dns_records = flatten([
    for key, value in var.dns_records : [
      for idx, record in value : merge(record, { identifier = "${key}-${idx}", dns_zone = (key) })
    ]
  ])

}

resource "ibm_dns_resource_record" "dns_record" {
  for_each    = length(ibm_dns_zone.dns_zone) > 0 ? { for record in local.dns_records : record.identifier => record } : {}
  instance_id = var.use_existing_dns_instance ? var.existing_dns_instance_id : ibm_resource_instance.dns_instance_hub[0].guid
  zone_id     = ibm_dns_zone.dns_zone[each.value.dns_zone].zone_id
  name        = each.value.name
  type        = each.value.type

  # Default ttl is 15 minutes [Refer](https://cloud.ibm.com/docs/dns-svcs?topic=dns-svcs-managing-dns-records&interface=ui)
  ttl   = try(each.value.ttl, 900)
  rdata = each.value.rdata

  # SRV values
  port     = each.value.type == "SRV" ? each.value.port : null
  priority = each.value.type == "SRV" ? each.value.priority : null
  protocol = each.value.type == "SRV" ? each.value.protocol : null
  service  = each.value.type == "SRV" ? startswith(each.value.service, "_") ? each.value.service : "_${each.value.service}" : null
  weight   = each.value.type == "SRV" ? each.value.weight : null

  # MX record
  preference = each.value.type == "MX" ? each.value.preference : null
}

locals {
  record_ids = {
    for k in distinct([for d in local.dns_records : d.dns_zone]) :
    k => [for d in local.dns_records : element(split("/", ibm_dns_resource_record.dns_record[d.identifier].id), 2) if d.dns_zone == k]
  }
}

##############################################################################
# Create VPN Gateways
##############################################################################

locals {
  # Convert the vpn_gateway input from list to a map
  vpn_gateway_map = { for gateway in var.vpn_gateways : gateway.name => gateway }
}

resource "ibm_is_vpn_gateway" "vpn_gateway" {
  for_each       = local.vpn_gateway_map
  name           = var.prefix != null ? "${var.prefix}-${each.key}" : each.key
  subnet         = local.subnets["${local.vpc_name}-${each.value.subnet_name}"].id
  mode           = each.value.mode
  resource_group = each.value.resource_group == null ? var.resource_group_id : each.value.resource_group
  tags           = var.tags
  access_tags    = each.value.access_tags

  timeouts {
    delete = "1h"
  }
}

##############################################################################
