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

  # ACL Objects - Split into inline rules and separate rules
  # Inline rules: ibm_rules and vpc_connectivity_rules (when prepend=true) + customer_rules
  # Separate rules: ibm_rules and vpc_connectivity_rules (when prepend=false) + deny_all_rules
  acl_object = {
    for network_acl in var.network_acls :
    network_acl.name => {
      name = network_acl.name
      # Only include rules that should be in the ACL resource itself
      inline_rules = flatten([
        # Prepend ibm rules if requested
        [
          for rule in local.ibm_cloud_internal_rules :
          rule if network_acl.add_ibm_cloud_internal_rules == true && network_acl.prepend_ibm_rules == true
        ],
        [
          for rule in local.vpc_connectivity_rules :
          rule if network_acl.add_vpc_connectivity_rules == true && network_acl.prepend_ibm_rules == true
        ],
        # Customer rules always in the middle
        network_acl.rules
      ])
      # Rules to be added via ibm_is_network_acl_rule (appended after customer rules)
      separate_rules = flatten([
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

  # Create inline ACL rules (ibm_rules + vpc_connectivity_rules when prepend=true, then customer_rules)
  dynamic "rules" {
    for_each = each.value.inline_rules
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

# Flatten all separate rules from all ACLs into a single map
locals {
  acl_separate_rules = merge([
    for acl_name, acl in local.acl_object : {
      for rule in acl.separate_rules :
      "${acl_name}-${rule.name}" => merge(rule, {
        acl_name = acl_name
      })
    } if var.create_subnets
  ]...)
}

# Create separate ACL rules that will be appended at the end
# This prevents re-ordering when customer_rules change
resource "ibm_is_network_acl_rule" "acl_rule" {
  for_each = local.acl_separate_rules

  network_acl = ibm_is_network_acl.network_acl[each.value.acl_name].id

  name        = each.value.name
  action      = each.value.action
  source      = each.value.source
  destination = each.value.destination
  direction   = each.value.direction

  protocol        = each.value.protocol
  port_min        = each.value.port_min
  port_max        = each.value.port_max
  source_port_min = each.value.source_port_min
  source_port_max = each.value.source_port_max
  type            = each.value.type
  code            = each.value.code
}

##############################################################################
