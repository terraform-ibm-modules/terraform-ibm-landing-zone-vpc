##############################################################################
# Network ACL
##############################################################################

locals {
  internal_rules = [
    # IaaS and PaaS Rules. Note that this coarse grained list will be narrowed in upcoming releases.
    {
      name        = "ibmflow-iaas-inbound"
      action      = "allow"
      source      = "161.26.0.0/16"
      destination = "0.0.0.0/0"
      direction   = "inbound"
      tcp         = null
      udp         = null
      icmp        = null
    },
    {
      name        = "ibmflow-iaas-outbound"
      action      = "allow"
      destination = "161.26.0.0/16"
      source      = "0.0.0.0/0"
      direction   = "outbound"
      tcp         = null
      udp         = null
      icmp        = null
    },
    {
      name        = "ibmflow-paas-inbound"
      action      = "allow"
      source      = "166.8.0.0/14"
      destination = "0.0.0.0/0"
      direction   = "inbound"
      tcp         = null
      udp         = null
      icmp        = null
    },
    {
      name        = "ibmflow-paas-outbound"
      action      = "allow"
      destination = "166.8.0.0/14"
      source      = "0.0.0.0/0"
      direction   = "outbound"
      tcp         = null
      udp         = null
      icmp        = null
    }
  ]

  ibm_cloud_internal_rules = flatten([
    for index, cidrs in var.network_cidrs != null ? var.network_cidrs : ["0.0.0.0/0"] :
    flatten([
      [
        for rule in local.internal_rules :
        merge(rule, {
          name   = "${rule.name}-${index}"
          source = cidrs
        }) if rule.direction == "outbound"
      ],
      [
        for rule in local.internal_rules :
        merge(rule, {
          name        = "${rule.name}-${index}"
          destination = cidrs
        }) if rule.direction == "inbound"
      ]
    ])
  ])

  vpc_inbound_rule = flatten([
    for index, cidrs in var.network_cidrs != null ? var.network_cidrs : ["0.0.0.0/0"] : [
      for address in data.ibm_is_vpc_address_prefixes.get_address_prefixes.address_prefixes :
      {
        name        = "ibmflow-allow-vpc-connectivity-inbound-${substr(address.id, -4, -1)}-${index}" # Providing unique rule names
        action      = "allow"
        source      = address.cidr
        destination = cidrs
        direction   = "inbound"
        tcp         = null
        udp         = null
        icmp        = null
      }
    ]
  ])
  vpc_outbound_rule = flatten([
    for address in data.ibm_is_vpc_address_prefixes.get_address_prefixes.address_prefixes : [
      for index, cidrs in var.network_cidrs != null ? var.network_cidrs : ["0.0.0.0/0"] :

      {
        name        = "ibmflow-allow-vpc-connectivity-outbound-${substr(address.id, -4, -1)}-${index}"
        action      = "allow"
        source      = cidrs
        destination = address.cidr
        direction   = "outbound"
        tcp         = null
        udp         = null
        icmp        = null
      }
    ]
  ])

  vpc_connectivity_rules = distinct(flatten(concat(local.vpc_inbound_rule, local.vpc_outbound_rule)))

  # The IBM VPC API does not allow action=deny with protocol=icmp_tcp_udp (the
  # "all protocols" sentinel).  Deny rules must target a specific protocol, so
  # the two generic deny-all rules are expanded into one rule per protocol per
  # direction (tcp / udp / icmp × inbound / outbound).
  deny_all_rules = [
    {
      name        = "ibmflow-deny-all-inbound-tcp"
      action      = "deny"
      source      = "0.0.0.0/0"
      destination = "0.0.0.0/0"
      direction   = "inbound"
      tcp         = {}
      udp         = null
      icmp        = null
    },
    {
      name        = "ibmflow-deny-all-inbound-udp"
      action      = "deny"
      source      = "0.0.0.0/0"
      destination = "0.0.0.0/0"
      direction   = "inbound"
      tcp         = null
      udp         = {}
      icmp        = null
    },
    {
      name        = "ibmflow-deny-all-inbound-icmp"
      action      = "deny"
      source      = "0.0.0.0/0"
      destination = "0.0.0.0/0"
      direction   = "inbound"
      tcp         = null
      udp         = null
      icmp        = {}
    },
    {
      name        = "ibmflow-deny-all-outbound-tcp"
      action      = "deny"
      source      = "0.0.0.0/0"
      destination = "0.0.0.0/0"
      direction   = "outbound"
      tcp         = {}
      udp         = null
      icmp        = null
    },
    {
      name        = "ibmflow-deny-all-outbound-udp"
      action      = "deny"
      source      = "0.0.0.0/0"
      destination = "0.0.0.0/0"
      direction   = "outbound"
      tcp         = null
      udp         = {}
      icmp        = null
    },
    {
      name        = "ibmflow-deny-all-outbound-icmp"
      action      = "deny"
      source      = "0.0.0.0/0"
      destination = "0.0.0.0/0"
      direction   = "outbound"
      tcp         = null
      udp         = null
      icmp        = {}
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
          # These rules cannot be added in a conditional operator due to inconsistent typing
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
  # due to a bug in terraform ternary conditional and nested map objects, use a for loop with if condition to only apply
  # ACLs if subnets are being created (not for existing subnets scenario)
  # The old version of this that had the bug was:
  # for_each       = var.create_subnets ? local.acl_object : {}
  for_each       = { for acl_key, acl_value in local.acl_object : acl_key => acl_value if var.create_subnets }
  name           = var.prefix != null ? "${var.prefix}-${each.key}" : each.key #already has name of vpc in each.key
  vpc            = local.vpc_id
  resource_group = var.resource_group_id
  access_tags    = var.access_tags
  tags           = var.tags

  # Create ACL rules
  dynamic "rules" {
    for_each = each.value.rules
    content {
      name        = rules.value.name
      action      = rules.value.action
      source      = rules.value.source
      destination = rules.value.destination
      direction   = rules.value.direction

      protocol = (
        rules.value.tcp != null ? "tcp" :
        rules.value.udp != null ? "udp" :
        rules.value.icmp != null ? "icmp" :
        "icmp_tcp_udp"
      )

      port_min = (
        rules.value.tcp != null ? lookup(rules.value.tcp, "port_min", null) :
        rules.value.udp != null ? lookup(rules.value.udp, "port_min", null) :
        null
      )

      port_max = (
        rules.value.tcp != null ? lookup(rules.value.tcp, "port_max", null) :
        rules.value.udp != null ? lookup(rules.value.udp, "port_max", null) :
        null
      )

      source_port_min = (
        rules.value.tcp != null ? lookup(rules.value.tcp, "source_port_min", null) :
        rules.value.udp != null ? lookup(rules.value.udp, "source_port_min", null) :
        null
      )

      source_port_max = (
        rules.value.tcp != null ? lookup(rules.value.tcp, "source_port_max", null) :
        rules.value.udp != null ? lookup(rules.value.udp, "source_port_max", null) :
        null
      )

      type = rules.value.icmp != null ? lookup(rules.value.icmp, "type", null) : null
      code = rules.value.icmp != null ? lookup(rules.value.icmp, "code", null) : null
    }
  }
}

##############################################################################
