##############################################################################
# Resource Group
##############################################################################

resource "ibm_resource_group" "resource_group" {
  count    = var.existing_resource_group_name != null ? 0 : 1
  name     = "${var.prefix}-rg"
  quota_id = null
}

data "ibm_resource_group" "existing_resource_group" {
  count = var.existing_resource_group_name != null ? 1 : 0
  name  = var.existing_resource_group_name
}

#############################################################################
# Deploy VPC
#############################################################################

module "deploy_vpc" {
  source               = "../"
  resource_group_id    = var.existing_resource_group_name != null ? data.ibm_resource_group.existing_resource_group[0].id : ibm_resource_group.resource_group[0].id
  region               = var.region
  prefix               = var.prefix
  security_group_rules = var.security_group_rules
  vpc_name             = var.prefix
}
