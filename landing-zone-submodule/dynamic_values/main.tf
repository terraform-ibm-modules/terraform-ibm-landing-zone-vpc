##############################################################################
# Locals
##############################################################################

locals {
  # Static reference for vpc with no gateways
  vpc_gateways = {
    zone-1 = false
    zone-2 = false
    zone-3 = false
  }
  vpc_list        = var.vpcs
  resource_groups = module.resource_groups.value
  vpcs            = module.vpcs.value
}

##############################################################################
