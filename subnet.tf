##############################################################################
# Multizone subnets
##############################################################################

locals {
  subnet_object = module.dynamic_values.subnet_map
  subnets = var.create_subnets ? ibm_is_subnet.subnet : { for subnet in data.ibm_is_subnet.subnet :
  subnet.name => subnet }
}

##############################################################################


##############################################################################
# Create new address prefixes
##############################################################################

resource "ibm_is_vpc_address_prefix" "subnet_prefix" {
  # Address prefixes replace subnet prefixes
  for_each = length(local.address_prefixes) > 0 || !var.create_subnets ? {} : local.subnet_object
  name     = each.value.prefix_name
  zone     = each.value.zone_name
  vpc      = local.vpc_id
  cidr     = each.value.cidr
}

##############################################################################


##############################################################################
# Create Subnets
##############################################################################

resource "ibm_is_subnet" "subnet" {
  for_each        = var.create_subnets ? local.subnet_object : {}
  vpc             = local.vpc_id
  name            = each.key
  zone            = each.value.zone_name
  resource_group  = var.resource_group_id
  ipv4_cidr_block = length(keys(local.address_prefixes)) == 0 ? ibm_is_vpc_address_prefix.subnet_prefix[each.value.prefix_name].cidr : each.value.cidr
  network_acl     = ibm_is_network_acl.network_acl[each.value.acl].id
  public_gateway  = each.value.public_gateway
  tags            = var.tags
  access_tags     = var.access_tags
  depends_on      = [ibm_is_vpc_address_prefix.address_prefixes]
}

data "ibm_is_subnet" "subnet" {
  count      = var.create_subnets == false ? length(var.existing_subnet_ids) : 0
  identifier = var.existing_subnet_ids[count.index]
}
##############################################################################
