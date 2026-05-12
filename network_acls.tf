##############################################################################
# Network ACL
##############################################################################

locals {
  internal_rules = [
    # IaaS and PaaS Rules. Note that this coarse grained list will be narrowed in upcoming releases.
    {
      name            = "ibmflow-iaas-inbound"
      action          = "allow"
      source          = "161.26.0.0/16"
      destination     = "0.0.0.0/0"
      direction       = "inbound"
      protocol        = null
      port_min        = null
      port_max        = null
      source_port_min = null
      source_port_max = null
      type            = null
      code            = null
    },
    {
      name            = "ibmflow-iaas-outbound"
      action          = "allow"
      destination     = "161.26.0.0/16"
      source          = "0.0.0.0/0"
      direction       = "outbound"
      protocol        = null
      port_min        = null
      port_max        = null
      source_port_min = null
      source_port_max = null
      type            = null
      code            = null
    },
    {
      name            = "ibmflow-paas-inbound"
      action          = "allow"
      source          = "166.8.0.0/14"
      destination     = "0.0.0.0/0"
      direction       = "inbound"
      protocol        = null
      port_min        = null
      port_max        = null
      source_port_min = null
      source_port_max = null
      type            = null
      code            = null
    },
    {
      name            = "ibmflow-paas-outbound"
      action          = "allow"
      destination     = "166.8.0.0/14"
      source          = "0.0.0.0/0"
      direction       = "outbound"
      protocol        = null
      port_min        = null
      port_max        = null
      source_port_min = null
      source_port_max = null
      type            = null
      code            = null
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
        name            = "ibmflow-allow-vpc-connectivity-inbound-${substr(address.id, -4, -1)}-${index}" # Providing unique rule names
        action          = "allow"
        source          = address.cidr
        destination     = cidrs
        direction       = "inbound"
        protocol        = null
        port_min        = null
        port_max        = null
        source_port_min = null
        source_port_max = null
        type            = null
        code            = null
      }
    ]
  ])
  vpc_outbound_rule = flatten([
    for address in data.ibm_is_vpc_address_prefixes.get_address_prefixes.address_prefixes : [
      for index, cidrs in var.network_cidrs != null ? var.network_cidrs : ["0.0.0.0/0"] :

      {
        name            = "ibmflow-allow-vpc-connectivity-outbound-${substr(address.id, -4, -1)}-${index}"
        action          = "allow"
        source          = cidrs
        destination     = address.cidr
        direction       = "outbound"
        protocol        = null
        port_min        = null
        port_max        = null
        source_port_min = null
        source_port_max = null
        type            = null
        code            = null
      }
    ]
  ])

  vpc_connectivity_rules = distinct(flatten(concat(local.vpc_inbound_rule, local.vpc_outbound_rule)))

  deny_all_rules = [
    {
      name            = "ibmflow-deny-all-inbound"
      action          = "deny"
      source          = "0.0.0.0/0"
      destination     = "0.0.0.0/0"
      direction       = "inbound"
      protocol        = null
      port_min        = null
      port_max        = null
      source_port_min = null
      source_port_max = null
      type            = null
      code            = null
    },
    {
      name            = "ibmflow-deny-all-outbound"
      action          = "deny"
      source          = "0.0.0.0/0"
      destination     = "0.0.0.0/0"
      direction       = "outbound"
      protocol        = null
      port_min        = null
      port_max        = null
      source_port_min = null
      source_port_max = null
      type            = null
      code            = null
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

      protocol        = rules.value.protocol
      port_min        = rules.value.port_min
      port_max        = rules.value.port_max
      source_port_min = rules.value.source_port_min
      source_port_max = rules.value.source_port_max
      type            = rules.value.type
      code            = rules.value.code
    }
  }
}

##############################################################################
