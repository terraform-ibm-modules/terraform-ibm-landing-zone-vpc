##############################################################################
# Resource Group Values
##############################################################################

module "resource_groups" {
  source   = "./config_modules/resource_groups"
  prefix   = var.prefix
  vpc_list = local.vpc_list
}

##############################################################################

##############################################################################
# [Unit Test] Resource Base Group Values
##############################################################################

module "resource_groups_base" {
  source   = "./config_modules/resource_groups"
  prefix   = "ut"
  vpc_list = ["management", "workload"]
}

locals {
  base_resource_group_contains_3_groups = regex("3", tostring(length(module.resource_groups_base.value)))
  base_rg_names                         = module.resource_groups_base.value.*.name
  base_rg_contains_management           = regex("true", tostring(contains(local.base_rg_names, "ut-management-rg")))
  base_rg_contains_service              = regex("true", tostring(contains(local.base_rg_names, "ut-management-rg")))
  base_rg_contains_workload             = regex("true", tostring(contains(local.base_rg_names, "ut-workload-rg")))
}

##############################################################################

##############################################################################
# [Unit Test] Resource All Group Values
##############################################################################

module "resource_groups_all" {
  source   = "./config_modules/resource_groups"
  prefix   = "ut"
  vpc_list = ["management", "workload"]
}

locals {
  all_resource_group_contains_3_groups = regex("3", tostring(length(module.resource_groups_all.value)))
  all_rg_names                         = module.resource_groups_all.value.*.name
  all_rg_contains_management           = regex("true", tostring(contains(local.all_rg_names, "ut-management-rg")))
  all_rg_contains_service              = regex("true", tostring(contains(local.all_rg_names, "ut-management-rg")))
  all_rg_contains_workload             = regex("true", tostring(contains(local.all_rg_names, "ut-workload-rg")))
}

##############################################################################
