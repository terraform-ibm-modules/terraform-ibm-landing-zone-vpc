##############################################################################
# Resource Group
# (if var.resource_group is null, create a new RG using var.prefix)
##############################################################################

resource "ibm_resource_group" "resource_group" {
  count    = var.resource_group != null ? 0 : 1
  name     = "${var.prefix}-rg"
  quota_id = null
}

data "ibm_resource_group" "existing_resource_group" {
  count = var.resource_group != null ? 1 : 0
  name  = var.resource_group
}

#############################################################################
# Locals
#############################################################################
locals {
  access_tags                            = []
  enable_vpc_flow_logs                   = true
  cos_plan                               = "standard"
  cos_location                           = "global"
  create_authorization_policy_vpc_to_cos = true
  network_cidrs                          = ["10.0.0.0/8", "164.0.0.0/8"]
  address_prefixes = {
    zone-1 = ["10.10.10.0/24"]
    zone-2 = ["10.20.10.0/24"]
    zone-3 = ["10.30.10.0/24"]
  }
}

#############################################################################
# Provision cloud object storage and bucket
#############################################################################

resource "ibm_resource_instance" "cos_instance" {
  count             = local.enable_vpc_flow_logs ? 1 : 0
  name              = "${var.prefix}-vpc-logs-cos"
  resource_group_id = var.resource_group != null ? data.ibm_resource_group.existing_resource_group[0].id : ibm_resource_group.resource_group[0].id
  service           = "cloud-object-storage"
  plan              = local.cos_plan
  location          = local.cos_location
}

resource "ibm_cos_bucket" "cos_bucket" {
  count                = local.enable_vpc_flow_logs ? 1 : 0
  bucket_name          = "${var.prefix}-vpc-logs-cos-bucket"
  resource_instance_id = ibm_resource_instance.cos_instance[0].id
  region_location      = var.region
  storage_class        = "standard"
}

#############################################################################
# Provision VPC
#############################################################################

module "slz_vpc" {
  source                                 = "../../"
  resource_group_id                      = var.resource_group != null ? data.ibm_resource_group.existing_resource_group[0].id : ibm_resource_group.resource_group[0].id
  region                                 = var.region
  name                                   = var.name
  prefix                                 = null
  tags                                   = var.resource_tags
  access_tags                            = local.access_tags
  enable_vpc_flow_logs                   = local.enable_vpc_flow_logs
  create_authorization_policy_vpc_to_cos = local.create_authorization_policy_vpc_to_cos
  existing_cos_instance_guid             = ibm_resource_instance.cos_instance[0].guid
  existing_storage_bucket_name           = ibm_cos_bucket.cos_bucket[0].bucket_name
  address_prefixes                       = local.address_prefixes
  network_cidrs                          = local.network_cidrs
}
