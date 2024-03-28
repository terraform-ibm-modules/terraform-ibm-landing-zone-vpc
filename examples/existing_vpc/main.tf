
##############################################################################
# Resource Group
##############################################################################

module "resource_group" {
  source  = "terraform-ibm-modules/resource-group/ibm"
  version = "1.1.5"
  # if an existing resource group is not set (null) create a new one using prefix
  existing_resource_group_name = var.existing_resource_group_name
}

module "slz_vpc" {
  source              = "../../"
  resource_group_id   = module.resource_group.resource_group_id
  region              = var.region
  create_vpc          = false
  existing_vpc_id     = var.vpc_id
  create_subnets      = false
  name                = var.name
  public_gateway_name = var.public_gateway_name
  existing_subnets    = [for id in var.subnet_ids : { "id" : id, "public_gateway" : false }]
}
