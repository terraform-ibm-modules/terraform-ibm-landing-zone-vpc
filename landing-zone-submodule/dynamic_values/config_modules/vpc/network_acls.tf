##############################################################################
# [Unit Test] Network ACLs
##############################################################################

module "default_network_acls" {
  source                     = "../network_acls"
  vpc_list                   = ["management", "workload"]
}

locals {
  default_network_acls_each_has_one = regex("true", tostring(
    length(
      distinct(
        flatten(
          [
            for network in module.default_network_acls.value :
            length(network) == 1
          ]
        )
      )
    ) == 1
  ))
}

##############################################################################
