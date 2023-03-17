
##############################################################################
# VPC Address Prefixes
##############################################################################

module "vpc_address_prefixes" {
  source                              = "../vpc_address_prefixes"
  vpcs                                = var.vpcs
  vpc_list                            = var.vpc_list
}

##############################################################################

##############################################################################
# Network ACLs
##############################################################################

module "network_acls" {
  source                     = "../network_acls"
  vpc_list                   = var.vpc_list
}

##############################################################################

##############################################################################
# VPC Subnet Tiers
##############################################################################

module "vpc_subnet_tiers" {
  source                              = "../vpc_subnet_tiers"
  vpcs                                = var.vpcs
  vpc_list                            = var.vpc_list
}

##############################################################################

##############################################################################
# Subnet CIDR
##############################################################################

module "subnet_cidr" {
  for_each          = module.vpc_subnet_tiers.value
  source            = "../subnet_cidr"
  network           = each.key
  subnet_tiers      = each.value
  vpc_list          = var.vpc_list
  vpcs              = var.vpcs
}

##############################################################################

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
}

##############################################################################

##############################################################################
# VPC Output
##############################################################################

output "value" {
  description = "List of VPCs for network"
  value = [
    for network in var.vpc_list :
    {
      default_security_group_rules = []
      prefix                       = network
      resource_group               = "${var.prefix}-${network}-rg"
      flow_logs_bucket_name        = "${network}-bucket"
      address_prefixes             = module.vpc_address_prefixes.value[network]
      network_acls                 = module.network_acls.value[network]
      use_public_gateways = (
         local.vpc_gateways
      )
      subnets = {
        for zone in [1, 2, 3] :
        "zone-${zone}" => [
          for subnet in keys(module.subnet_cidr[network].value["zone-${zone}"]) :
          {
            name           = "${subnet}-zone-${zone}"
            cidr           = module.subnet_cidr[network].value["zone-${zone}"][subnet]
            public_gateway = null
            acl_name       = "${network}-acl"
          }
        ]
      }
    }
  ]
}

##############################################################################
