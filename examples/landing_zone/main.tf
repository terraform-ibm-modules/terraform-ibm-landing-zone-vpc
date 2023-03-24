##############################################################################
# Workload Resource Group
##############################################################################

module "workload_resource_group" {
  source = "git::https://github.com/terraform-ibm-modules/terraform-ibm-resource-group.git?ref=v1.0.5"
  # if an existing resource group is not set (null) create a new one using prefix
  resource_group_name          = var.workload_resource_group == null ? "${var.prefix}-workload-rg" : null
  existing_resource_group_name = var.workload_resource_group
}

module "management_resource_group" {
  source = "git::https://github.com/terraform-ibm-modules/terraform-ibm-resource-group.git?ref=v1.0.5"
  # if an existing resource group is not set (null) create a new one using prefix
  resource_group_name          = var.management_resource_group == null ? "${var.prefix}-workload-rg" : null
  existing_resource_group_name = var.management_resource_group
}

#############################################################################
# Provision cloud object storage and bucket
#############################################################################

resource "ibm_resource_instance" "cos_instance" {
  count = var.enable_vpc_flow_logs ? 1 : 0

  name              = "${var.prefix}-vpc-logs-cos"
  resource_group_id = module.workload_resource_group.resource_group_id
  service           = "cloud-object-storage"
  plan              = var.cos_plan
  location          = var.cos_location
}

resource "ibm_cos_bucket" "cos_bucket" {
  count = var.enable_vpc_flow_logs ? 1 : 0

  bucket_name          = "${var.prefix}-vpc-logs-cos-bucket"
  resource_instance_id = ibm_resource_instance.cos_instance[0].id
  region_location      = var.region
  storage_class        = "standard"
}

#############################################################################
# Provision VPC
#############################################################################

module "workload_vpc" {
  source                                 = "../../landing-zone-submodule/workload-vpc/"
  resource_group_id                      = module.workload_resource_group.resource_group_id
  region                                 = var.region
  prefix                                 = var.prefix
  tags                                   = var.resource_tags
  enable_vpc_flow_logs                   = var.enable_vpc_flow_logs
  create_authorization_policy_vpc_to_cos = var.create_authorization_policy_vpc_to_cos
  existing_cos_instance_guid             = ibm_resource_instance.cos_instance[0].guid
  existing_cos_bucket_name           = ibm_cos_bucket.cos_bucket[0].bucket_name
}


module "management_vpc" {
  source                                 = "../../landing-zone-submodule/management-vpc/"
  resource_group_id                      = module.management_resource_group.resource_group_id
  region                                 = var.region
  prefix                                 = var.prefix
  tags                                   = var.resource_tags
}