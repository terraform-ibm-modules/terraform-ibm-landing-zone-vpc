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

  # Replace deprecated nested protocol blocks with top-level attributes.
  protocol = (
    each.value.tcp != null ? "tcp" :
    each.value.udp != null ? "udp" :
    each.value.icmp != null ? "icmp" :
    null
  )

  port_min = (
    each.value.tcp != null ? lookup(each.value.tcp, "port_min", null) :
    each.value.udp != null ? lookup(each.value.udp, "port_min", null) :
    null
  )

  port_max = (
    each.value.tcp != null ? lookup(each.value.tcp, "port_max", null) :
    each.value.udp != null ? lookup(each.value.udp, "port_max", null) :
    null
  )

  type = each.value.icmp != null ? lookup(each.value.icmp, "type", null) : null
  code = each.value.icmp != null ? lookup(each.value.icmp, "code", null) : null
}

##############################################################################
