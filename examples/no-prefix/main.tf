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
  name              = "${var.prefix}-vpc-logs-cos"
  resource_group_id = var.resource_group != null ? data.ibm_resource_group.existing_resource_group[0].id : ibm_resource_group.resource_group[0].id
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
# Provision VPC
#############################################################################

module "slz_vpc" {
  source                                 = "../../"
  resource_group_id                      = var.resource_group != null ? data.ibm_resource_group.existing_resource_group[0].id : ibm_resource_group.resource_group[0].id
  region                                 = var.region
  name                                   = var.name
  prefix                                 = null
  tags                                   = var.resource_tags
  access_tags                            = []
  enable_vpc_flow_logs                   = true
  create_authorization_policy_vpc_to_cos = true
  existing_cos_instance_guid             = ibm_resource_instance.cos_instance.guid
  existing_storage_bucket_name           = ibm_cos_bucket.cos_bucket.bucket_name
  address_prefixes = {
    zone-1 = ["10.10.10.0/24"]
    zone-2 = ["10.20.10.0/24"]
    zone-3 = ["10.30.10.0/24"]
  }
  network_cidrs = ["10.0.0.0/8", "164.0.0.0/8"]
}
