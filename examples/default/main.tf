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
# Provision cloud object storage and bucket
#############################################################################

resource "ibm_resource_instance" "cos_instance" {
  count             = var.enable_vpc_flow_logs ? 1 : 0
  name              = "${var.prefix}-vpc-logs-cos"
  resource_group_id = var.resource_group != null ? data.ibm_resource_group.existing_resource_group[0].id : ibm_resource_group.resource_group[0].id
  service           = "cloud-object-storage"
  plan              = var.cos_plan
  location          = var.cos_location
}

resource "ibm_cos_bucket" "cos_bucket" {
  count                = var.enable_vpc_flow_logs ? 1 : 0
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
  is_vpc_existing                        = var.is_vpc_existing
  name                                   = var.name
  prefix                                 = var.prefix
  tags                                   = var.resource_tags
  access_tags                            = var.access_tags
  enable_vpc_flow_logs                   = var.enable_vpc_flow_logs
  create_authorization_policy_vpc_to_cos = var.create_authorization_policy_vpc_to_cos
  existing_cos_instance_guid             = ibm_resource_instance.cos_instance[0].guid
  existing_storage_bucket_name           = ibm_cos_bucket.cos_bucket[0].bucket_name
  address_prefixes                       = var.address_prefixes
  network_cidrs                          = var.network_cidrs
}
