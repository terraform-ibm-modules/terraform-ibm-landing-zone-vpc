locals {
  prefix = var.prefix != null ? (trimspace(var.prefix) != "" ? "${var.prefix}-" : "") : ""
}

##############################################################################
# Resource Group
##############################################################################

module "resource_group" {
  source                       = "terraform-ibm-modules/resource-group/ibm"
  version                      = "1.4.0"
  existing_resource_group_name = var.existing_resource_group_name
}


#############################################################################
# Provision cloud object storage and bucket
#############################################################################

resource "ibm_resource_instance" "cos_instance" {
  name              = "${var.prefix}-vpc-logs-cos"
  resource_group_id = module.resource_group.resource_group_id
  service           = "cloud-object-storage"
  plan              = "standard"
  location          = "global"
}

resource "ibm_cos_bucket" "cos_bucket" {
  bucket_name          = "${var.prefix}-vpc-logs-cos-bucket"
  resource_instance_id = ibm_resource_instance.cos_instance.id
  region_location      = var.region
  storage_class        = "standard"
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
  network_acls                           = var.network_acls
  security_group_rules                   = var.security_group_rules
  clean_default_sg_acl                   = var.clean_default_security_group_acl
  use_public_gateways                    = local.public_gateway_object
  address_prefixes                       = var.address_prefixes
  routes                                 = var.routes
  enable_vpc_flow_logs                   = var.enable_vpc_flow_logs
  create_authorization_policy_vpc_to_cos = !var.skip_vpc_cos_iam_auth_policy
  existing_cos_instance_guid             = var.enable_vpc_flow_logs ? ibm_resource_instance.cos_instance[0].guid : null
  existing_storage_bucket_name           = var.enable_vpc_flow_logs ? ibm_cos_bucket.cos_bucket[0].bucket_name : null
}
