##############################################################################
# [Unit Test] Default VPC Subnet Tiers
##############################################################################

module "default_vpc_subnet_tiers" {
  source                              = "../vpc_subnet_tiers"
  vpcs                                = ["management", "workload"]
  vpc_list                            = ["management", "workload"]
}

locals {
  default_vpc_subnet_tiers_network_length  = regex("2", length(keys(module.default_vpc_subnet_tiers.value)))
  default_vpc_subnet_tiers_rest_same = regex("true", tostring(
    length(
      distinct(
        flatten(
          [
            for network in module.default_vpc_subnet_tiers.value :
            [
              for zone in concat(network != "management" ? ["zone-1"] : [], ["zone-2", "zone-3"]) :
              [
                for tier in ["vsi", "vpe"] :
                contains(network[zone], tier)
              ]
            ]
          ]
        )
      )
    ) == 1
  ))
}

##############################################################################
