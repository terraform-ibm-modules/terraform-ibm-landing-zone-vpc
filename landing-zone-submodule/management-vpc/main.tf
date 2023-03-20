##############################################################################
# Resource Group
##############################################################################

module "resource_group" {
  source = "git::https://github.com/terraform-ibm-modules/terraform-ibm-resource-group.git?ref=v1.0.5"
  # if an existing resource group is not set (null) create a new one using prefix
  resource_group_name          = var.resource_group == null ? "${var.prefix}-resource-group" : null
  existing_resource_group_name = var.resource_group
}

#############################################################################
# Provision VPC
#############################################################################

module "management_vpc" {
  source                      = "../../"
  name                        = "management"
  tags                        = var.tags
  resource_group_id           = module.resource_group.resource_group_id
  region                      = var.region
  prefix                      = var.prefix
  network_cidr                = var.network_cidr
  classic_access              = var.classic_access
  use_manual_address_prefixes = var.use_manual_address_prefixes
  default_network_acl_name    = var.default_network_acl_name
  default_security_group_name = var.default_security_group_name
  security_group_rules        = var.default_security_group_rules == null ? [] : var.default_security_group_rules
  default_routing_table_name  = var.default_routing_table_name
  address_prefixes            = var.address_prefixes
  network_acls                = var.network_acls
  use_public_gateways         = var.use_public_gateways
  subnets                     = var.subnets
}
