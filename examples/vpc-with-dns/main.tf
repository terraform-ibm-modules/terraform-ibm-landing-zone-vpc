##############################################################################
# Resource Group
##############################################################################

module "resource_group" {
  source  = "terraform-ibm-modules/resource-group/ibm"
  version = "1.4.0"
  # if an existing resource group is not set (null) create a new one using prefix
  resource_group_name          = var.resource_group == null ? "${var.prefix}-resource-group" : null
  existing_resource_group_name = var.resource_group
}

#############################################################################
# Locals
#############################################################################
locals {
  subnets = {
    zone-1 = [
      {
        name           = "subnet-a"
        cidr           = "10.10.10.0/24"
        public_gateway = true
        acl_name       = "vpc-acl"
      }
    ],
    zone-2 = [
      {
        name           = "subnet-b"
        cidr           = "10.20.10.0/24"
        public_gateway = false
        acl_name       = "vpc-acl"
      }
    ]
  }
}

#############################################################################
# Provision VPC
#############################################################################

module "slz_vpc" {
  source            = "../../"
  resource_group_id = module.resource_group.resource_group_id
  region            = var.region
  name              = var.name
  prefix            = var.prefix
  tags              = var.resource_tags
  enable_hub        = true
  dns_zones         = var.dns_zones
  dns_records       = var.dns_records
  subnets           = local.subnets
}
