##############################################################################
# Resource Group
##############################################################################

module "resource_group" {
  source  = "terraform-ibm-modules/resource-group/ibm"
  version = "1.1.0"
  # if an existing resource group is not set (null) create a new one using prefix
  resource_group_name          = var.resource_group == null ? "${var.prefix}-resource-group" : null
  existing_resource_group_name = var.resource_group
}

#############################################################################
# Provision Hub VPC
#############################################################################

module "hub_vpc" {
  source            = "../../"
  resource_group_id = module.resource_group.resource_group_id
  region            = var.region
  name              = "${var.prefix}-hub-${var.name}"
  prefix            = var.prefix
  tags              = var.resource_tags
}

#############################################################################
# Provision Spoke VPC
#############################################################################

module "spoke_vpc" {
  source            = "../../"
  resource_group_id = module.resource_group.resource_group_id
  region            = var.region
  name              = "${var.prefix}-spoke-${var.name}"
  prefix            = var.prefix
  tags              = var.resource_tags
  enable_hub        = var.enable_hub
  resolver_type     = "manual"
  manual_servers = [{
    "address" : "192.168.3.4"
    "zone_affinity" = "us-south-1"
  }]
}
