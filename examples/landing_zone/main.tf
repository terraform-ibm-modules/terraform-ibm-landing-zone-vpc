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
# Provision cloud object storage and bucket
#############################################################################

module "cos_bucket" {
  count                 = var.enable_vpc_flow_logs ? 1 : 0
  source                = "git::https://github.com/terraform-ibm-modules/terraform-ibm-cos.git?ref=v6.5.1"
  resource_group_id     = module.resource_group.resource_group_id
  region                = var.region
  cross_region_location = null
  cos_instance_name     = "${var.prefix}-vpc-logs-cos"
  cos_tags              = var.resource_tags
  bucket_name           = "${var.prefix}-vpc-logs-cos-bucket"
  encryption_enabled    = false
  retention_enabled     = false
}

#############################################################################
# Provision VPC
#############################################################################

module "workload_vpc" {
  source                                 = "../../landing-zone-submodule/workload-vpc/"
  resource_group_id                      = module.resource_group.resource_group_id
  region                                 = var.region
  prefix                                 = var.prefix
  tags                                   = var.resource_tags
  access_tags                            = var.access_tags
  enable_vpc_flow_logs                   = var.enable_vpc_flow_logs
  create_authorization_policy_vpc_to_cos = var.create_authorization_policy_vpc_to_cos
  existing_cos_instance_guid             = module.cos_bucket[0].cos_instance_guid
  existing_cos_bucket_name               = module.cos_bucket[0].bucket_name[0]
  clean_default_security_group           = true
  clean_default_acl                      = true
  ibmcloud_api_key                       = var.ibmcloud_api_key
}


module "management_vpc" {
  source                       = "../../landing-zone-submodule/management-vpc/"
  resource_group_id            = module.resource_group.resource_group_id
  region                       = var.region
  prefix                       = var.prefix
  tags                         = var.resource_tags
  clean_default_security_group = true
  clean_default_acl            = true
  ibmcloud_api_key             = var.ibmcloud_api_key
}


##############################################################################
# Transit Gateway connects the 2 VPCs
##############################################################################

module "tg_gateway_connection" {
  source                    = "git::https://github.com/terraform-ibm-modules/terraform-ibm-transit-gateway.git?ref=v2.1.1"
  transit_gateway_name      = "${var.prefix}-tg"
  region                    = var.region
  global_routing            = false
  resource_tags             = var.resource_tags
  resource_group_id         = module.resource_group.resource_group_id
  vpc_connections           = [module.workload_vpc.vpc_crn, module.management_vpc.vpc_crn]
  classic_connections_count = 0
}
