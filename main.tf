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
  validate_existing_subnet_id = !var.create_subnets && var.existing_subnet_ids == null ? tobool("If var.create_subnet is false, then provide a value for var.existing_subnet_ids to create subnets.") : true
  # tflint-ignore: terraform_unused_declarations
  validate_existing_vpc_and_subnet = var.create_vpc == true && var.create_subnets == false ? tobool("If user is not providing a vpc then they should also not be providing a subnet") : true
}

##############################################################################
# Create new VPC
##############################################################################

resource "ibm_is_vpc" "vpc" {
  count                       = var.create_vpc == true ? 1 : 0
  name                        = var.prefix != null ? "${var.prefix}-${var.name}-vpc" : "${var.name}-vpc"
  resource_group              = var.resource_group_id
  classic_access              = var.classic_access
  address_prefix_management   = length([for prefix in values(coalesce(var.address_prefixes, {})) : prefix if prefix != null]) != 0 ? "manual" : null
  default_network_acl_name    = var.default_network_acl_name
  default_security_group_name = var.default_security_group_name
  default_routing_table_name  = var.default_routing_table_name
  tags                        = var.tags
  access_tags                 = var.access_tags
  no_sg_acl_rules             = var.clean_default_sg_acl

  dns {
    enable_hub = var.enable_hub
  }
}

data "ibm_is_vpc" "vpc" {
  count = var.create_vpc == false ? 1 : 0
  id    = var.existing_vpc_id
}

locals {
  vpc_id = var.create_vpc ? var.existing_vpc_id : ibm_is_vpc.vpc[0].id
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
  depends_on = [ibm_iam_authorization_policy.policy]

  create_duration = "30s"
}

##############################################################################
# Create vpc route resource
##############################################################################

resource "ibm_is_vpc_routing_table" "route_table" {
  for_each                      = module.dynamic_values.routing_table_map
  name                          = var.prefix != null ? "${var.prefix}-${var.name}-route-${each.value.name}" : "${var.name}-route-${each.value.name}"
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
  name           = var.prefix != null ? "${var.prefix}-${var.name}-public-gateway-${each.key}" : "${var.name}-public-gateway-${each.key}"
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

locals {
  # tflint-ignore: terraform_unused_declarations
  validate_vpc_flow_logs_inputs = (var.enable_vpc_flow_logs) ? ((var.create_authorization_policy_vpc_to_cos) ? ((var.existing_cos_instance_guid != null && var.existing_storage_bucket_name != null) ? true : tobool("Please provide COS instance & bucket name to create flow logs collector.")) : ((var.existing_storage_bucket_name != null) ? true : tobool("Please provide COS bucket name to create flow logs collector"))) : false
}

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

  name           = var.prefix != null ? "${var.prefix}-${var.name}-logs" : "${var.name}-logs"
  target         = local.vpc_id
  active         = var.is_flow_log_collector_active
  storage_bucket = var.existing_storage_bucket_name
  resource_group = var.resource_group_id
  tags           = var.tags
  access_tags    = var.access_tags
}

##############################################################################
