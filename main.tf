##############################################################################
# terraform-ibm-landing-zone-vpc
##############################################################################
locals {
  # input variable validation
  # tflint-ignore: terraform_unused_declarations
  validate_default_secgroup_rules = var.clean_default_sg_acl && (var.security_group_rules != null && length(var.security_group_rules) > 0) ? tobool("var.clean_default_sg_acl is true and var.security_group_rules are not empty, which are in direct conflict of each other. If you would like the default VPC Security Group to be empty, you must remove default rules from var.security_group_rules.") : true

  # tflint-ignore: terraform_unused_declarations
  validate_existing_vpc_id = !var.create_vpc && var.existing_vpc_id == null ? tobool("If var.create_vpc is false, then provide a value for var.existing_vpc_id to create vpc.") : true

  # tflint-ignore: terraform_unused_declarations
  validate_existing_subnet_id = !var.create_subnets && length(var.existing_subnets) == 0 ? tobool("If var.create_subnet is false, then provide a value for var.existing_subnets to create subnets.") : true
  # tflint-ignore: terraform_unused_declarations
  validate_existing_vpc_and_subnet = var.create_vpc == true && var.create_subnets == false ? tobool("If user is not providing a vpc then they should also not be providing a subnet") : true

  # tflint-ignore: terraform_unused_declarations
  validate_hub_vpc_input = (var.hub_vpc_id != null && var.hub_vpc_crn != null) ? tobool("var.hub_vpc_id and var.hub_vpc_crn are mutually exclusive. Hence cannot have values at the same time.") : true

  # tflint-ignore: terraform_unused_declarations
  validate_hub_vpc_id_input = (var.enable_hub_vpc_id && var.hub_vpc_id == null) ? tobool("var.hub_vpc_id must be passed when var.enable_hub_vpc_id is True.") : true

  # tflint-ignore: terraform_unused_declarations
  validate_enable_hub_vpc_id_input = (!var.enable_hub_vpc_id && var.hub_vpc_id != null) ? tobool("var.enable_hub_vpc_id must be true when var.hub_vpc_id is not null.") : true

  # tflint-ignore: terraform_unused_declarations
  validate_hub_vpc_crn_input = (var.enable_hub_vpc_crn && var.hub_vpc_crn == null) ? tobool("var.hub_vpc_crn must be passed when var.enable_hub_vpc_crn is True.") : true

  # tflint-ignore: terraform_unused_declarations
  validate_enable_hub_vpc_crn_input = (!var.enable_hub_vpc_crn && var.hub_vpc_crn != null) ? tobool("var.enable_hub_vpc_crn must be true when var.hub_vpc_crn is not null.") : true

  # tflint-ignore: terraform_unused_declarations
  validate_manual_servers_input = (var.resolver_type == "manual" && length(var.manual_servers) == 0) ? tobool("var.manual_servers must be set when var.resolver_type is manual") : true

  # tflint-ignore: terraform_unused_declarations
  validate_resolver_type_input = (var.resolver_type != null && var.update_delegated_resolver == true) ? tobool("var.resolver_type cannot be set if var.update_delegated_resolver is set to true. Only one type of resolver can be created by VPC.") : true

  # tflint-ignore: terraform_unused_declarations
  validate_vpc_flow_logs_inputs = (var.enable_vpc_flow_logs) ? ((var.create_authorization_policy_vpc_to_cos) ? ((var.existing_cos_instance_guid != null && var.existing_storage_bucket_name != null) ? true : tobool("Please provide COS instance & bucket name to create flow logs collector.")) : ((var.existing_storage_bucket_name != null) ? true : tobool("Please provide COS bucket name to create flow logs collector"))) : false

  # tflint-ignore: terraform_unused_declarations
  validate_skip_spoke_auth_policy_input = (var.hub_account_id == null && !var.skip_spoke_auth_policy && !var.enable_hub && (var.enable_hub_vpc_id || var.enable_hub_vpc_crn)) ? tobool("var.hub_account_id must be set when var.skip_spoke_auth_policy is False and either var.enable_hub_vpc_id or var.enable_hub_vpc_crn is true.") : true
}

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
# DNS ZONE
##############################################################################

resource "ibm_dns_zone" "dns_zone" {
  name = var.dns_zone_name
  # instance_id = (var.enable_hub && !var.skip_custom_resolver_hub_creation) ? (var.use_existing_dns_instance ? var.existing_dns_instance_id : ibm_resource_instance.dns_instance_hub[0].guid) : null
  instance_id = var.existing_dns_instance_id
  # var.use_existing_dns_instance ? var.existing_dns_instance_id : ibm_resource_instance.dns_instance_hub[0].guid
  description = var.dns_zone_description
  label       = var.dns_zone_label
}

##############################################################################
# DNS Records
##############################################################################

resource "ibm_dns_resource_record" "dns_record" {
  for_each    = { for idx, record in var.dns_records : idx => record } # Loop through a list of DNS records
  instance_id = var.use_existing_dns_instance ? var.existing_dns_instance_id : ibm_resource_instance.dns_instance_hub[0].guid
  zone_id     = ibm_dns_zone.dns_zone.id # Reference to the zone created above
  name        = each.value.name
  type        = each.value.type
  rdata       = each.value.rdata
  ttl         = each.value.ttl
  preference  = each.value.preference
  priority    = each.value.priority
  port        = each.value.port
  protocol    = each.value.protocol
  service     = each.value.service
  weight      = each.value.weight
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
  name           = var.prefix != null ? "${var.prefix}-${var.name}-vpc" : var.name
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
      for_each = (var.enable_hub_vpc_id || var.enable_hub_vpc_crn) && var.update_delegated_resolver ? [1] : []
      content {
        type    = "delegated"
        vpc_id  = var.hub_vpc_id != null ? var.hub_vpc_id : null
        vpc_crn = var.hub_vpc_crn != null ? var.hub_vpc_crn : null
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

# Enable Hub to dns resolve in spoke VPC
resource "ibm_is_vpc_dns_resolution_binding" "vpc_dns_resolution_binding_id" {
  count = (var.enable_hub == false && var.enable_hub_vpc_id) ? 1 : 0
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

resource "ibm_is_vpc_dns_resolution_binding" "vpc_dns_resolution_binding_crn" {
  count = (var.enable_hub == false && var.enable_hub_vpc_crn) ? 1 : 0
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
}

##############################################################################

##############################################################################
# Add VPC to Flow Logs
##############################################################################

# Create authorization policy to allow VPC to access COS instance
resource "ibm_iam_authorization_policy" "policy" {
  count = (var.enable_vpc_flow_logs) ? ((var.create_authorization_policy_vpc_to_cos) ? 1 : 0) : 0

  source_service_name         = "is"
  source_resource_type        = "flow-log-collector"
  target_service_name         = "cloud-object-storage"
  target_resource_instance_id = var.existing_cos_instance_guid
  roles                       = ["Writer"]
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
