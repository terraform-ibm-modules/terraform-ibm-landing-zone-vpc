# VPC
#########################################################
# data using account provider to retrieve edge (hub) VPC in DNS account
#########################################################



module "vpc" {
  for_each = var.vpcs

  source  = "terraform-ibm-modules/landing-zone-vpc/ibm"
  version = "8.9.1"

  resource_group_id = var.resource_group_id

  region = var.region

  name = format("%s-%s-%s-vpc", var.account_name, each.key, var.region)

  address_prefixes = each.value.address_prefixes

  default_security_group_name = join("-", compact([var.account_name, each.key, var.region, "vpc-default-sg"]))
  default_routing_table_name  = join("-", compact([var.account_name, each.key, var.region, "vpc-default-rt"]))
  default_network_acl_name    = join("-", compact([var.account_name, each.key, var.region, "vpc-default-nacl"]))

  network_acls = [
      {
        name = join("-", compact([var.account_name, each.key, var.region, "vpc-nacl"]))

        add_ibm_cloud_internal_rules = each.value.add_ibm_cloud_internal_rules
        add_vpc_connectivity_rules   = each.value.add_vpc_connectivity_rules
        prepend_ibm_rules            = each.value.prepend_ibm_rules

        rules = each.value.acl_rules
      }
  ]

  security_group_rules = each.value.security_group_rules

  use_public_gateways = each.value.use_public_gateways

  subnets      = each.value.subnets

}