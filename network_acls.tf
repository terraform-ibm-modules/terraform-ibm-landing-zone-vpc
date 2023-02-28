##############################################################################
# Network ACL
##############################################################################

locals {
  ibm_cloud_internal_rules = [
    # IaaS and PaaS Rules. Note that this coarse grained list will be narrowed in upcoming releases.
    {
      name        = "ibmflow-iaas-inbound"
      action      = "allow"
      source      = "161.26.0.0/16"
      destination = var.network_cidr != null ? var.network_cidr : "0.0.0.0/0"
      direction   = "inbound"
      tcp         = null
      udp         = null
      icmp        = null
    },
    {
      name        = "ibmflow-iaas-outbound"
      action      = "allow"
      destination = "161.26.0.0/16"
      source      = var.network_cidr != null ? var.network_cidr : "0.0.0.0/0"
      direction   = "outbound"
      tcp         = null
      udp         = null
      icmp        = null
    },
    {
      name        = "ibmflow-paas-inbound"
      action      = "allow"
      source      = "166.8.0.0/14"
      destination = var.network_cidr != null ? var.network_cidr : "0.0.0.0/0"
      direction   = "inbound"
      tcp         = null
      udp         = null
      icmp        = null
    },
    {
      name        = "ibmflow-paas-outbound"
      action      = "allow"
      destination = "166.8.0.0/14"
      source      = var.network_cidr != null ? var.network_cidr : "0.0.0.0/0"
      direction   = "outbound"
      tcp         = null
      udp         = null
      icmp        = null
    }
  ]

  vpc_connectivity_rules = [
    # All connectivity across any subnet within VPC
    # TODO: narrow down to VPC address spaces
    {
      name        = "ibmflow-allow-vpc-connectivity-inbound"
      action      = "allow"
      source      = var.network_cidr != null ? var.network_cidr : "0.0.0.0/0"
      destination = var.network_cidr != null ? var.network_cidr : "0.0.0.0/0"
      direction   = "inbound"
      tcp         = null
      udp         = null
      icmp        = null
    },
    {
      name        = "ibmflow-allow-vpc-connectivity-outbound"
      action      = "allow"
      source      = var.network_cidr != null ? var.network_cidr : "0.0.0.0/0"
      destination = var.network_cidr != null ? var.network_cidr : "0.0.0.0/0"
      direction   = "outbound"
      tcp         = null
      udp         = null
      icmp        = null
    }
  ]

  deny_all_rules = [
    {
      name        = "ibmflow-deny-all-inbound"
      action      = "deny"
      source      = "0.0.0.0/0"
      destination = "0.0.0.0/0"
      direction   = "inbound"
      tcp         = null
      udp         = null
      icmp        = null
    },
    {
      name        = "ibmflow-deny-all-outbound"
      action      = "deny"
      source      = "0.0.0.0/0"
      destination = "0.0.0.0/0"
      direction   = "outbound"
      tcp         = null
      udp         = null
      icmp        = null
    }
  ]

  # ACL Objects
  acl_object = {
    for network_acl in var.network_acls :
    network_acl.name => {
      name = network_acl.name
      rules = flatten([
        # Prepend ibm rules
        [
          # These rules cannot be added in a conditional operator due to inconsistant typing
          # This will add all internal rules if the acl object contains add_ibm_cloud_internal_rules rules
          for rule in local.ibm_cloud_internal_rules :
          rule if network_acl.add_ibm_cloud_internal_rules == true && network_acl.prepend_ibm_rules == true
        ],
        [
          for rule in local.vpc_connectivity_rules :
          rule if network_acl.add_vpc_connectivity_rules == true && network_acl.prepend_ibm_rules == true
        ],
        # Customer rules
        network_acl.rules,
        # Append ibm rules
        [
          for rule in local.ibm_cloud_internal_rules :
          rule if network_acl.add_ibm_cloud_internal_rules == true && network_acl.prepend_ibm_rules != true
        ],
        [
          for rule in local.vpc_connectivity_rules :
          rule if network_acl.add_vpc_connectivity_rules == true && network_acl.prepend_ibm_rules != true
        ],
        # Best practice to add deny all at the end of ACL
        local.deny_all_rules
      ])
    }
  }
}

resource "ibm_is_network_acl" "network_acl" {
  for_each       = local.acl_object
  name           = "${var.prefix}-${each.key}" #already has name of vpc in each.key
  vpc            = ibm_is_vpc.vpc.id
  resource_group = var.resource_group_id

  # Create ACL rules
  dynamic "rules" {
    for_each = each.value.rules
    content {
      name        = rules.value.name
      action      = rules.value.action
      source      = rules.value.source
      destination = rules.value.destination
      direction   = rules.value.direction

      dynamic "tcp" {
        for_each = (
          # if rules null
          rules.value.tcp == null
          # empty array
          ? []
          # otherwise check each possible field against how many of the values are
          # equal to null and only include rules where one of the values is not null
          # this allows for patterns to include `tcp` blocks for conversion to list
          # while still not creating a rule. default behavior would force the rule to
          # be included if all indiviual values are set to null
          : length([
            for value in ["port_min", "port_max", "source_port_min", "source_port_min"] :
            true if lookup(rules.value["tcp"], value, null) == null
          ]) == 4
          ? []
          : [rules.value]
        )
        content {
          port_min        = lookup(rules.value.tcp, "port_min", null)
          port_max        = lookup(rules.value.tcp, "port_max", null)
          source_port_min = lookup(rules.value.tcp, "source_port_min", null)
          source_port_max = lookup(rules.value.tcp, "source_port_max", null)
        }
      }

      dynamic "udp" {
        for_each = (
          # if rules null
          rules.value.udp == null
          # empty array
          ? []
          # otherwise check each possible field against how many of the values are
          # equal to null and only include rules where one of the values is not null
          # this allows for patterns to include `udp` blocks for conversion to list
          # while still not creating a rule. default behavior would force the rule to
          # be included if all indiviual values are set to null
          : length([
            for value in ["port_min", "port_max", "source_port_min", "source_port_min"] :
            true if lookup(rules.value["udp"], value, null) == null
          ]) == 4
          ? []
          : [rules.value]
        )
        content {
          port_min        = lookup(rules.value.udp, "port_min", null)
          port_max        = lookup(rules.value.udp, "port_max", null)
          source_port_min = lookup(rules.value.udp, "source_port_min", null)
          source_port_max = lookup(rules.value.udp, "source_port_max", null)
        }
      }

      dynamic "icmp" {
        for_each = (
          # if rules null
          rules.value.icmp == null
          # empty array
          ? []
          # otherwise check each possible field against how many of the values are
          # equal to null and only include rules where one of the values is not null
          # this allows for patterns to include `udp` blocks for conversion to list
          # while still not creating a rule. default behavior would force the rule to
          # be included if all indiviual values are set to null
          : length([
            for value in ["code", "type"] :
            true if lookup(rules.value["icmp"], value, null) == null
          ]) == 2
          ? []
          : [rules.value]
        )
        content {
          type = rules.value.icmp.type
          code = rules.value.icmp.code
        }
      }
    }
  }
}

##############################################################################
