locals {
  prefix = var.prefix != null ? (var.prefix != "" ? var.prefix : null) : null
}

##############################################################################
# Resource Group
##############################################################################

module "resource_group" {
  source                       = "terraform-ibm-modules/resource-group/ibm"
  version                      = "1.1.6"
  resource_group_name          = var.use_existing_resource_group == false ? try("${local.prefix}-${var.resource_group_name}", var.resource_group_name) : null
  existing_resource_group_name = var.use_existing_resource_group == true ? var.resource_group_name : null
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
  bucket_name = try("${local.prefix}-${var.cos_bucket_name}", var.cos_bucket_name)

  bucket_config = [{
    access_tags                   = var.access_tags
    bucket_name                   = local.bucket_name
    kms_encryption_enabled        = var.kms_encryption_enabled_bucket
    kms_guid                      = var.kms_encryption_enabled_bucket ? module.existing_kms_crn_parser[0].service_instance : null
    kms_key_crn                   = var.kms_encryption_enabled_bucket ? var.existing_kms_instance_crn : null
    skip_iam_authorization_policy = var.skip_cos_kms_auth_policy
    management_endpoint_type      = var.management_endpoint_type_for_bucket
    storage_class                 = var.cos_bucket_class
    resource_instance_id          = var.existing_cos_instance_crn
    region_location               = var.region
    force_delete                  = true
  }]
}

module "cos_buckets" {
  count          = var.enable_vpc_flow_logs ? 1 : 0
  source         = "terraform-ibm-modules/cos/ibm//modules/buckets"
  version        = "8.19.2"
  bucket_configs = local.bucket_config
}

#######################################################################################################################
# KMS Key
#######################################################################################################################

# parse KMS details from the existing KMS instance CRN
module "existing_kms_crn_parser" {
  count   = var.kms_encryption_enabled_bucket && var.existing_kms_instance_crn != null ? 1 : 0
  source  = "terraform-ibm-modules/common-utilities/ibm//modules/crn-parser"
  version = "1.1.0"
  crn     = var.existing_kms_instance_crn
}

locals {
  # fetch KMS region from existing_kms_instance_crn if KMS resources are required
  kms_region = var.kms_encryption_enabled_bucket && var.existing_kms_instance_crn != null ? module.existing_kms_crn_parser[0].region : null

  kms_key_ring_name = try("${var.prefix}-${var.kms_key_ring_name}", var.kms_key_ring_name)
  kms_key_name      = try("${var.prefix}-${var.kms_key_name}", var.kms_key_name)

  create_kms_key = var.existing_kms_key_crn == null ? ((var.enable_vpc_flow_logs && var.kms_encryption_enabled_bucket && var.existing_kms_instance_crn != null) ? true : false) : false
}

module "kms" {
  count                       = local.create_kms_key ? 1 : 0 # no need to create any KMS resources if not passing an existing KMS CRN or existing KMS key CRN is provided
  source                      = "terraform-ibm-modules/kms-all-inclusive/ibm"
  version                     = "4.19.5"
  create_key_protect_instance = false
  region                      = local.kms_region
  existing_kms_instance_crn   = var.existing_kms_instance_crn
  key_ring_endpoint_type      = var.kms_endpoint_type
  key_endpoint_type           = var.kms_endpoint_type
  keys = [
    {
      key_ring_name         = local.kms_key_ring_name
      existing_key_ring     = false
      force_delete_key_ring = true
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
  # //TO DO
  # to create use_public_gateways object
}

module "vpc" {
  source                      = "../../"
  resource_group_id           = module.resource_group.resource_group_id
  region                      = var.region
  create_vpc                  = true
  name                        = var.vpc_name
  prefix                      = local.prefix
  tags                        = var.resource_tags
  access_tags                 = var.access_tags
  subnets                     = var.subnets
  default_network_acl_name    = var.default_network_acl_name
  default_security_group_name = var.default_security_group_name
  default_routing_table_name  = var.default_routing_table_name
  network_acls                = var.network_acls
  clean_default_sg_acl        = var.clean_default_sg_acl
  # use_public_gateways = local.public_gateway_object
  address_prefixes                       = var.address_prefixes
  routes                                 = var.routes
  enable_vpc_flow_logs                   = var.enable_vpc_flow_logs
  create_authorization_policy_vpc_to_cos = !var.skip_vpc_cos_authorization_policy
  existing_cos_instance_guid             = var.enable_vpc_flow_logs ? module.existing_cos_crn_parser[0].service_instance : null
  existing_storage_bucket_name           = var.enable_vpc_flow_logs ? module.cos_buckets[0].buckets[0].bucket_name : null
}
