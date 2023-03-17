##############################################################################
# Variables
##############################################################################

variable "prefix" {
  description = "A unique identifier for resources. Must begin with a letter and end with a letter or number. This prefix will be prepended to any resources provisioned by this template. Prefixes must be 16 or fewer characters."
  type        = string

  validation {
    error_message = "Prefix must begin and end with a letter and contain only letters, numbers, and - characters. Prefixes must end with a letter or number and be 16 or fewer characters."
    condition     = can(regex("^([A-z]|[a-z][-a-z0-9]*[a-z0-9])$", var.prefix)) && length(var.prefix) <= 16
  }
}

variable "vpc_list" {
  description = "List of VPCs for pattern"
  type        = list(string)
}

##############################################################################

##############################################################################
# Locals
##############################################################################

locals {
  # List of resource groups used by default
  resource_group_list = flatten([
    ["service"]
  ])

  # Create reference list
  dynamic_rg_list = flatten([
    [
      "Default",
      "default",
    ]
  ])

  # All Resource groups
  all_resource_groups = distinct(concat(local.resource_group_list, var.vpc_list))
}

##############################################################################

##############################################################################
# Outputs
##############################################################################

output "value" {
  description = "List of resource groups"
  value = [
    for group in local.all_resource_groups :
    {
      name       = contains(local.dynamic_rg_list, group) ? group : "${var.prefix}-${group}-rg"
      create     = contains(local.dynamic_rg_list, group) ? false : true
      use_prefix = contains(local.dynamic_rg_list, group) ? true : false
    }
  ]
}

##############################################################################
