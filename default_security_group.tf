##############################################################################
# Update default security group
##############################################################################

locals {
  # Convert to object
  security_group_rule_object = {
    for rule in var.security_group_rules :
    rule.name => rule
  }
}

resource "ibm_is_security_group_rule" "default_vpc_rule" {
  for_each   = local.security_group_rule_object
  group      = var.create_vpc == true ? ibm_is_vpc.vpc[0].default_security_group : data.ibm_is_vpc.vpc.default_security_group
  direction  = each.value.direction
  remote     = each.value.remote
  local      = each.value.local
  ip_version = each.value.ip_version
  protocol   = each.value.protocol
  port_min   = each.value.port_min
  port_max   = each.value.port_max
  type       = each.value.type
  code       = each.value.code
}

##############################################################################
