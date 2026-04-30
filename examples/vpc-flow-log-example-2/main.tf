##############################################################################
# Local Variables
##############################################################################


locals {
  # Full prefix combining prefix and environment
  full_prefix = "${var.prefix}-${var.environment}"

  # Resource group environment key
  rg_environment = var.environment
}
##############################################################################
# Resource Group Module
##############################################################################

module "iz_resource_group" {
  source              = "terraform-ibm-modules/resource-group/ibm"
  version             = "1.6.0"
  resource_group_name = "${local.full_prefix}-${var.resource_group_name}"
}

##############################################################################
# KMS All-Inclusive Module
##############################################################################

module "kms" {
  source                      = "terraform-ibm-modules/kms-all-inclusive/ibm"
  version                     = "4.19.3"
  resource_group_id           = module.iz_resource_group.resource_group_id
  region                      = var.region
  key_protect_instance_name   = "${local.full_prefix}-kms"
  key_ring_endpoint_type      = "public"
  key_endpoint_type           = "public"
  key_protect_allowed_network = "public-and-private"
  keys = [
    {
      key_ring_name = "${local.full_prefix}-key-ring"
      force_delete  = true
      keys = [
        {
          key_name     = var.kms_key_name
          force_delete = true
        }
      ]
    }
  ]
}

##############################################################################
# Cloud Object Storage Module
##############################################################################

module "cos" {
  source                              = "terraform-ibm-modules/cos/ibm"
  version                             = "10.14.9"
  resource_group_id                   = module.iz_resource_group.resource_group_id
  region                              = var.region
  cos_instance_name                   = "${local.full_prefix}-cos-instance"
  bucket_name                         = "${local.full_prefix}-cos-bucket"
  kms_encryption_enabled              = true
  bucket_storage_class                = "standard"
  kms_key_crn                         = module.kms.keys["${local.full_prefix}-key-ring.${var.kms_key_name}"].crn
  management_endpoint_type_for_bucket = var.management_endpoint_type_for_bucket
  force_delete                        = var.force_delete_buckets
  skip_iam_authorization_policy       = false
  archive_days                        = null
  expire_days                         = 365
  add_bucket_name_suffix              = false
  resource_keys = [{
    name                      = "cos-resource-key"
    generate_hmac_credentials = true
    role                      = "Manager"
  }]
}

##############################################################################
# VPC Module with Flow Logs
##############################################################################

data "ibm_iam_account_settings" "iam_account_settings" {}

module "ibm_vpc" {
  source     = "terraform-ibm-modules/landing-zone-vpc/ibm"
  version    = "8.17.2"
  depends_on = [ibm_iam_authorization_policy.policy]
  # Core VPC Configuration
  resource_group_id = module.iz_resource_group.resource_group_id
  region            = var.region
  prefix            = local.full_prefix
  tags              = var.tags
  name              = lookup(var.vpc_info, "name")

  # Network Configuration
  network_acls         = lookup(var.vpc_info, "network_acls")
  network_cidrs        = lookup(var.vpc_info, "network_cidr")
  use_public_gateways  = lookup(var.vpc_info, "use_public_gateways")
  subnets              = lookup(var.vpc_info, "subnets")
  clean_default_sg_acl = var.clean_default_sg_acl

  # Flow Logs Configuration with Fixed Authorization Policy
  # The module now creates authorization policy with both Reader and Writer roles:
  # - Reader: Allows flow log collector to list buckets in COS instance
  # - Writer: Allows flow log collector to write flow logs to specific bucket
  enable_vpc_flow_logs                   = true
  existing_cos_instance_guid             = module.cos.cos_instance_guid
  existing_storage_bucket_name           = module.cos.bucket_name
  create_authorization_policy_vpc_to_cos = false
}

resource "ibm_iam_authorization_policy" "policy" {
  depends_on           = [module.cos]
  source_service_name  = "is"
  source_resource_type = "flow-log-collector"
  roles                = ["Reader", "Writer"]

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
    value    = module.cos.cos_instance_guid
  }

  resource_attributes {
    name     = "resource"
    operator = "stringEquals"
    value    = "${local.full_prefix}-cos-bucket"
  }

  resource_attributes {
    name     = "resourceType"
    operator = "stringEquals"
    value    = "bucket"
  }

  lifecycle {
    create_before_destroy = true
  }
}
