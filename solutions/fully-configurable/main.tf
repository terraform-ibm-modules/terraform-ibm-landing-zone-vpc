locals {
  prefix = var.prefix != null ? (trimspace(var.prefix) != "" ? "${var.prefix}-" : "") : ""
}

##############################################################################
# Resource Group
##############################################################################

module "resource_group" {
  source                       = "terraform-ibm-modules/resource-group/ibm"
  version                      = "1.2.0"
  existing_resource_group_name = var.existing_resource_group_name
}

#############################################################################
# COS Bucket for VPC flow logs
#############################################################################

# parse COS details from the existing COS instance CRN
module "existing_cos_crn_parser" {
  count   = var.existing_cos_instance_crn != null ? 1 : 0
  source  = "terraform-ibm-modules/common-utilities/ibm//modules/crn-parser"
  version = "1.1.0"
  crn     = var.existing_cos_instance_crn
}

locals {
  cos_instance_guid                        = var.existing_cos_instance_crn != null ? module.existing_cos_crn_parser[0].service_instance : null
  cos_account_id                           = var.existing_cos_instance_crn != null ? module.existing_cos_crn_parser[0].account_id : null
  bucket_name                              = "${local.prefix}${var.flow_logs_cos_bucket_name}"
  kms_guid                                 = var.kms_encryption_enabled_bucket ? (length(module.existing_kms_key_crn_parser) > 0 ? module.existing_kms_key_crn_parser[0].service_instance : module.existing_kms_instance_crn_parser[0].service_instance) : null
  kms_account_id                           = var.kms_encryption_enabled_bucket ? (length(module.existing_kms_key_crn_parser) > 0 ? module.existing_kms_key_crn_parser[0].account_id : module.existing_kms_instance_crn_parser[0].account_id) : null
  kms_service_name                         = var.kms_encryption_enabled_bucket ? (length(module.existing_kms_key_crn_parser) > 0 ? module.existing_kms_key_crn_parser[0].service_name : module.existing_kms_instance_crn_parser[0].service_name) : null
  cos_kms_key_crn                          = var.kms_encryption_enabled_bucket ? (length(module.existing_kms_key_crn_parser) > 0 ? var.existing_flow_logs_bucket_kms_key_crn : module.kms[0].keys[format("%s.%s", local.kms_key_ring_name, local.kms_key_name)].crn) : null
  create_cos_kms_iam_auth_policy           = var.enable_vpc_flow_logs && var.kms_encryption_enabled_bucket && !var.skip_cos_kms_iam_auth_policy
  create_cross_account_cos_kms_auth_policy = (local.create_cos_kms_iam_auth_policy && var.ibmcloud_kms_api_key == null) ? false : (local.kms_account_id != null ? (local.cos_account_id != local.kms_account_id) : false)

  # configuration for the flow logs bucket
  bucket_config = [{
    access_tags                   = var.access_tags
    bucket_name                   = local.bucket_name
    add_bucket_name_suffix        = var.add_bucket_name_suffix
    kms_encryption_enabled        = var.kms_encryption_enabled_bucket
    kms_guid                      = local.kms_guid
    kms_key_crn                   = local.cos_kms_key_crn
    skip_iam_authorization_policy = local.create_cross_account_cos_kms_auth_policy || !local.create_cos_kms_iam_auth_policy
    management_endpoint_type      = var.management_endpoint_type_for_bucket
    storage_class                 = var.cos_bucket_class
    resource_instance_id          = var.existing_cos_instance_crn
    region_location               = var.region
    force_delete                  = true
    archive_rule = var.flow_logs_cos_bucket_archive_days != null ? {
      enable = true
      days   = var.flow_logs_cos_bucket_archive_days
      type   = var.flow_logs_cos_bucket_archive_type
    } : null
    expire_rule = var.flow_logs_cos_bucket_expire_days != null ? {
      enable = true
      days   = var.flow_logs_cos_bucket_expire_days
    } : null
    retention_rule = var.flow_logs_cos_bucket_enable_retention ? {
      default   = var.flow_logs_cos_bucket_default_retention_days
      maximum   = var.flow_logs_cos_bucket_maximum_retention_days
      minimum   = var.flow_logs_cos_bucket_minimum_retention_days
      permanent = var.flow_logs_cos_bucket_enable_permanent_retention
    } : null
    object_versioning_enabled = var.flow_logs_cos_bucket_enable_object_versioning
  }]
}

# Create COS bucket using the defined bucket configuration
module "cos_buckets" {
  count          = var.enable_vpc_flow_logs ? 1 : 0
  depends_on     = [time_sleep.wait_for_cross_account_authorization_policy[0]]
  source         = "terraform-ibm-modules/cos/ibm//modules/buckets"
  version        = "8.21.17"
  bucket_configs = local.bucket_config
}

# Create IAM Authorization Policy to allow COS to access KMS for the encryption key, if cross account KMS is passed in
resource "ibm_iam_authorization_policy" "cos_kms_policy" {
  count                       = local.create_cross_account_cos_kms_auth_policy ? 1 : 0
  provider                    = ibm.kms
  source_service_account      = local.cos_account_id
  source_service_name         = "cloud-object-storage"
  source_resource_instance_id = local.cos_instance_guid
  roles                       = ["Reader"]
  description                 = "Allow the COS instance ${local.cos_instance_guid} to read the ${local.kms_service_name} key ${local.cos_kms_key_crn} from the instance ${local.kms_guid}"
  resource_attributes {
    name     = "serviceName"
    operator = "stringEquals"
    value    = local.kms_service_name
  }
  resource_attributes {
    name     = "accountId"
    operator = "stringEquals"
    value    = local.kms_account_id
  }
  resource_attributes {
    name     = "serviceInstance"
    operator = "stringEquals"
    value    = local.kms_guid
  }
  resource_attributes {
    name     = "resourceType"
    operator = "stringEquals"
    value    = "key"
  }
  resource_attributes {
    name     = "resource"
    operator = "stringEquals"
    value    = local.cos_kms_key_crn
  }
  # Scope of policy now includes the key, so ensure to create new policy before
  # destroying old one to prevent any disruption to every day services.
  lifecycle {
    create_before_destroy = true
  }
}

# workaround for https://github.com/IBM-Cloud/terraform-provider-ibm/issues/4478
resource "time_sleep" "wait_for_cross_account_authorization_policy" {
  depends_on = [ibm_iam_authorization_policy.cos_kms_policy]
  count      = local.create_cross_account_cos_kms_auth_policy ? 1 : 0

  create_duration = "30s"
}

#######################################################################################################################
# KMS Key
#######################################################################################################################

# parse KMS details from the existing KMS instance CRN
module "existing_kms_instance_crn_parser" {
  count   = var.kms_encryption_enabled_bucket && var.existing_kms_instance_crn != null ? 1 : 0
  source  = "terraform-ibm-modules/common-utilities/ibm//modules/crn-parser"
  version = "1.1.0"
  crn     = var.existing_kms_instance_crn
}

# parse KMS details from the existing KMS instance CRN
module "existing_kms_key_crn_parser" {
  count   = var.kms_encryption_enabled_bucket && var.existing_flow_logs_bucket_kms_key_crn != null ? 1 : 0
  source  = "terraform-ibm-modules/common-utilities/ibm//modules/crn-parser"
  version = "1.1.0"
  crn     = var.existing_flow_logs_bucket_kms_key_crn
}

locals {
  # fetch KMS region from existing_kms_instance_crn if KMS resources are required
  kms_region = var.kms_encryption_enabled_bucket && var.existing_kms_instance_crn != null ? module.existing_kms_instance_crn_parser[0].region : null

  kms_key_ring_name = "${local.prefix}${var.kms_key_ring_name}"
  kms_key_name      = "${local.prefix}${var.kms_key_name}"

  create_kms_key = (var.enable_vpc_flow_logs && var.kms_encryption_enabled_bucket) ? (var.existing_flow_logs_bucket_kms_key_crn == null ? (var.existing_kms_instance_crn != null ? true : false) : false) : false
}

# KMS root key for flow logs COS bucket
module "kms" {
  providers = {
    ibm = ibm.kms
  }
  count                       = local.create_kms_key ? 1 : 0 # no need to create any KMS resources if not passing an existing KMS CRN or existing KMS key CRN is provided
  source                      = "terraform-ibm-modules/kms-all-inclusive/ibm"
  version                     = "5.0.1"
  create_key_protect_instance = false
  region                      = local.kms_region
  existing_kms_instance_crn   = var.existing_kms_instance_crn
  key_ring_endpoint_type      = var.kms_endpoint_type
  key_endpoint_type           = var.kms_endpoint_type
  keys = [
    {
      key_ring_name     = local.kms_key_ring_name
      existing_key_ring = false
      keys = [
        {
          key_name                 = local.kms_key_name
          standard_key             = false
          rotation_interval_month  = 3
          dual_auth_delete_enabled = false
          force_delete             = true
        }
      ]
    }
  ]
}

#############################################################################
# VPC
#############################################################################

locals {
  # create 'use_public_gateways' object
  public_gateway_object = {
    for key, value in var.subnets : key => value != null ? length([for sub in value : sub.public_gateway if sub.public_gateway]) > 0 ? [for sub in value : sub.public_gateway if sub.public_gateway][0] : false : false
  }
}

# Create VPC
module "vpc" {
  source                                 = "../../"
  resource_group_id                      = module.resource_group.resource_group_id
  region                                 = var.region
  create_vpc                             = true
  name                                   = var.vpc_name
  prefix                                 = local.prefix != "" ? trimspace(var.prefix) : null
  tags                                   = var.resource_tags
  access_tags                            = var.access_tags
  subnets                                = var.subnets
  default_network_acl_name               = var.default_network_acl_name
  default_security_group_name            = var.default_security_group_name
  default_routing_table_name             = var.default_routing_table_name
  network_acls                           = var.network_acls
  security_group_rules                   = var.security_group_rules
  clean_default_sg_acl                   = var.clean_default_security_group_acl
  use_public_gateways                    = local.public_gateway_object
  address_prefixes                       = var.address_prefixes
  routes                                 = var.routes
  enable_vpc_flow_logs                   = var.enable_vpc_flow_logs
  create_authorization_policy_vpc_to_cos = !var.skip_vpc_cos_iam_auth_policy
  existing_cos_instance_guid             = var.enable_vpc_flow_logs ? local.cos_instance_guid : null
  existing_storage_bucket_name           = var.enable_vpc_flow_logs ? module.cos_buckets[0].buckets[local.bucket_name].bucket_name : null
  vpn_gateways                           = var.vpn_gateways
}

#############################################################################
# VPE Gateway
#############################################################################

module "vpe_gateway" {
  source               = "terraform-ibm-modules/vpe-gateway/ibm"
  version              = "4.5.0"
  resource_group_id    = module.resource_group.resource_group_id
  region               = var.region
  prefix               = local.prefix
  security_group_ids   = var.vpe_gateway_security_group_ids
  vpc_name             = module.vpc.vpc_name
  vpc_id               = module.vpc.vpc_id
  subnet_zone_list     = module.vpc.subnet_zone_list
  cloud_services       = var.vpe_gateway_cloud_services
  cloud_service_by_crn = var.vpe_gateway_cloud_service_by_crn
  service_endpoints    = var.vpe_gateway_service_endpoints
  reserved_ips         = var.vpe_gateway_reserved_ips
}
