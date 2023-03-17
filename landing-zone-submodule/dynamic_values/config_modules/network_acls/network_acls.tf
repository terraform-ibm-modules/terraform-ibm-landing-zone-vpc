##############################################################################
# Variables
##############################################################################

variable "vpc_list" {
  description = "List of VPCs"
  type        = list(string)
}

##############################################################################

##############################################################################
# ACL Rules
##############################################################################

module "acl_rules" {
  source = "../acl_rules"
}

##############################################################################

##############################################################################
# Outputs
##############################################################################

output "value" {
  description = "Map of network ACLs by VPC"
  value = {
    for network in var.vpc_list :
    (network) => [
      for network_acl in [network] :
      {
        name              = "${network_acl}-acl"
        add_cluster_rules =  false
        rules = concat(
          module.acl_rules.default_vpc_rules,
          network_acl != network ? module.acl_rules[network_acl] : []
        )
      }
    ]
  }
}

##############################################################################