#############################################################################
# Provision VPC
#############################################################################

module "workload_vpc" {
  source                                 = "../../"
  name                                   = "workload"
  tags                                   = var.tags
  access_tags                            = var.access_tags
  resource_group_id                      = var.resource_group_id
  region                                 = var.region
  prefix                                 = var.prefix
  network_cidr                           = var.network_cidr
  classic_access                         = var.classic_access
  default_network_acl_name               = var.default_network_acl_name
  default_security_group_name            = var.default_security_group_name
  security_group_rules                   = var.default_security_group_rules == null ? [] : var.default_security_group_rules
  default_routing_table_name             = var.default_routing_table_name
  address_prefixes                       = var.address_prefixes
  network_acls                           = var.network_acls
  use_public_gateways                    = var.use_public_gateways
  subnets                                = var.subnets
  enable_vpc_flow_logs                   = var.enable_vpc_flow_logs
  create_authorization_policy_vpc_to_cos = var.create_authorization_policy_vpc_to_cos
  existing_cos_instance_guid             = var.existing_cos_instance_guid
  existing_storage_bucket_name           = var.existing_cos_bucket_name
}
