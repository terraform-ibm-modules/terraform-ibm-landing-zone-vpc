##############################################################################
# Resource Group
##############################################################################

module "resource_group" {
  source  = "terraform-ibm-modules/resource-group/ibm"
  version = "1.1.5"
  # if an existing resource group is not set (null) create a new one using prefix
  resource_group_name          = var.resource_group == null ? "${var.prefix}-resource-group" : null
  existing_resource_group_name = var.resource_group
}

#############################################################################
# Provision cloud object storage and bucket
#############################################################################

module "cos_bucket" {
  count                  = var.enable_vpc_flow_logs ? 1 : 0
  source                 = "terraform-ibm-modules/cos/ibm"
  version                = "7.4.1"
  resource_group_id      = module.resource_group.resource_group_id
  region                 = var.region
  cross_region_location  = null
  cos_instance_name      = "${var.prefix}-vpc-logs-cos"
  cos_tags               = var.resource_tags
  bucket_name            = "${var.prefix}-vpc-logs-cos-bucket"
  kms_encryption_enabled = false
  retention_enabled      = false
}

#############################################################################
# Provision VPC
#############################################################################

module "workload_vpc" {
  source                                 = "../../modules/workload-vpc/"
  resource_group_id                      = module.resource_group.resource_group_id
  region                                 = var.region
  prefix                                 = "${var.prefix}-workload"
  tags                                   = var.resource_tags
  access_tags                            = var.access_tags
  enable_vpc_flow_logs                   = var.enable_vpc_flow_logs
  create_authorization_policy_vpc_to_cos = var.create_authorization_policy_vpc_to_cos
  existing_cos_instance_guid             = module.cos_bucket[0].cos_instance_guid
  existing_cos_bucket_name               = module.cos_bucket[0].bucket_name
  clean_default_sg_acl                   = true
}


module "management_vpc" {
  source               = "../../modules/management-vpc/"
  resource_group_id    = module.resource_group.resource_group_id
  region               = var.region
  prefix               = "${var.prefix}-management"
  tags                 = var.resource_tags
  clean_default_sg_acl = true
}


##############################################################################
# Transit Gateway connects the 2 VPCs
##############################################################################

module "tg_gateway_connection" {
  source                    = "terraform-ibm-modules/transit-gateway/ibm"
  version                   = "2.4.2"
  transit_gateway_name      = "${var.prefix}-tg"
  region                    = var.region
  global_routing            = false
  resource_tags             = var.resource_tags
  resource_group_id         = module.resource_group.resource_group_id
  vpc_connections           = [module.workload_vpc.vpc_crn, module.management_vpc.vpc_crn]
  classic_connections_count = 0
}
