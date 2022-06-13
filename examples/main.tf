##############################################################################
# Resource Group
##############################################################################

resource "ibm_resource_group" "resource_group" {
  name     = "${var.prefix}-rg"
  quota_id = null
}

#############################################################################
# Deploy VPC
#############################################################################

module "deploy_vpc" {
  source     = "../"
  resource_group_id  = ibm_resource_group.resource_group.id
  region = var.region
  prefix = var.prefix
  security_group_rules = var.security_group_rules
  vpc_name = var.vpc_name
}
