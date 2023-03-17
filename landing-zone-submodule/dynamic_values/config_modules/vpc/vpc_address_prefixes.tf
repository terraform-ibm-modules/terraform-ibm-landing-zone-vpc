##############################################################################
# [Unit Test] VPC Address Prefixes No F5
##############################################################################

module "vpc_address_prefixes_no_f5" {
  source                              = "../vpc_address_prefixes"
  vpcs                                = ["management", "workload"]
  vpc_list                            = ["management", "workload"]
}

locals {
  vpc_address_prefixes_two_networks        = regex("2", length(keys(module.vpc_address_prefixes_no_f5.value)))
  vpc_address_prefixes_workload_no_address = regex("0", length(module.vpc_address_prefixes_no_f5.value["workload"].zone-2))
}

##############################################################################
