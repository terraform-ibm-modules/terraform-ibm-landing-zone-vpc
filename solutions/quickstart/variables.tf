##############################################################################
# Input Variables
##############################################################################

variable "ibmcloud_api_key" {
  type        = string
  description = "The IBM Cloud API key to deploy resources."
  sensitive   = true
}

variable "provider_visibility" {
  description = "Set the visibility value for the IBM terraform provider. Supported values are `public`, `private`, `public-and-private`. [Learn more](https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs/guides/custom-service-endpoints)."
  type        = string
  default     = "private"

  validation {
    condition     = contains(["public", "private", "public-and-private"], var.provider_visibility)
    error_message = "Invalid visibility option. Allowed values are 'public', 'private', or 'public-and-private'."
  }
}

variable "existing_resource_group_name" {
  type        = string
  description = "The name of an existing resource group to provision the resources. [Learn more](https://cloud.ibm.com/docs/account?topic=account-rgs&interface=ui#create_rgs) about how to create a resource group."
  default     = "Default"
}

variable "prefix" {
  type        = string
  nullable    = true
  description = "The prefix to add to all resources that this solution creates (e.g `prod`, `test`, `dev`). To skip using a prefix, set this value to null or an empty string. [Learn more](https://terraform-ibm-modules.github.io/documentation/#/prefix.md)."

  validation {
    # - null and empty string is allowed
    # - Must not contain consecutive hyphens (--): length(regexall("--", var.prefix)) == 0
    # - Starts with a lowercase letter: [a-z]
    # - Contains only lowercase letters (a–z), digits (0–9), and hyphens (-)
    # - Must not end with a hyphen (-): [a-z0-9]
    condition = (var.prefix == null || var.prefix == "" ? true :
      alltrue([
        can(regex("^[a-z][-a-z0-9]*[a-z0-9]$", var.prefix)),
        length(regexall("--", var.prefix)) == 0
      ])
    )
    error_message = "Prefix must begin with a lowercase letter and may contain only lowercase letters, digits, and hyphens '-'. It must not end with a hyphen('-'), and cannot contain consecutive hyphens ('--')."
  }

  validation {
    # must not exceed 16 characters in length
    condition     = var.prefix == null || var.prefix == "" ? true : length(var.prefix) <= 16
    error_message = "Prefix must not exceed 16 characters."
  }
}

variable "vpc_name" {
  default     = "vpc"
  description = "Name of the VPC. If a prefix input variable is specified, the prefix is added to the name in the `<prefix>-<name>` format."
  type        = string
}

variable "region" {
  type        = string
  description = "The region to provision all resources in. [Learn more](https://terraform-ibm-modules.github.io/documentation/#/region) about how to select different regions for different services."
  default     = "us-south"
}

variable "resource_tags" {
  type        = list(string)
  description = "The list of tags to add to the VPC instance."
  default     = []
}

variable "access_tags" {
  type        = list(string)
  description = "The list of access tags to add to the VPC instance."
  default     = []
}

##############################################################################
# Subnets
##############################################################################

variable "subnets" {
  description = "List of subnets for the vpc. For each item in each array, a subnet will be created. Items can be either CIDR blocks or total ipv4 addresses. Public gateways will be enabled only in zones where a gateway has been created. [Learn more](https://github.com/terraform-ibm-modules/terraform-ibm-landing-zone-vpc/blob/main/solutions/fully-configurable/DA-types.md#subnets-)."
  type = object({
    zone-1 = list(object({
      name           = string
      cidr           = string
      public_gateway = optional(bool)
      acl_name       = string
      no_addr_prefix = optional(bool, false) # do not automatically add address prefix for subnet, overrides other conditions if set to true
      subnet_tags    = optional(list(string), [])
    }))
    zone-2 = optional(list(object({
      name           = string
      cidr           = string
      public_gateway = optional(bool)
      acl_name       = string
      no_addr_prefix = optional(bool, false) # do not automatically add address prefix for subnet, overrides other conditions if set to true
      subnet_tags    = optional(list(string), [])
    })))
    zone-3 = optional(list(object({
      name           = string
      cidr           = string
      public_gateway = optional(bool)
      acl_name       = string
      no_addr_prefix = optional(bool, false) # do not automatically add address prefix for subnet, overrides other conditions if set to true
      subnet_tags    = optional(list(string), [])
    })))
  })

  default = {
    zone-1 = [
      {
        name           = "subnet-a"
        cidr           = "10.10.10.0/24"
        public_gateway = true
        acl_name       = "vpc-acl"
        no_addr_prefix = false
      }
    ],
    zone-2 = [
      {
        name           = "subnet-b"
        cidr           = "10.20.10.0/24"
        public_gateway = true
        acl_name       = "vpc-acl"
        no_addr_prefix = false
      }
    ],
    zone-3 = [
      {
        name           = "subnet-c"
        cidr           = "10.30.10.0/24"
        public_gateway = true
        acl_name       = "vpc-acl"
        no_addr_prefix = false
      }
    ]
  }

  validation {
    condition     = alltrue([for key, value in var.subnets : value != null ? length([for subnet in value : subnet.public_gateway if subnet.public_gateway]) > 1 ? false : true : true])
    error_message = "var.subnets has more than one public gateway in a zone. Only one public gateway can be attached to a zone for the virtual private cloud."
  }
}

##############################################################################
# Network ACLs
##############################################################################

variable "network_acls" {
  description = "The list of ACLs to create. Provide at least one rule for each ACL. [Learn more](https://github.com/terraform-ibm-modules/terraform-ibm-landing-zone-vpc/blob/main/solutions/fully-configurable/DA-types.md#network-acls-)."
  type = list(
    object({
      name                         = string
      add_ibm_cloud_internal_rules = optional(bool)
      add_vpc_connectivity_rules   = optional(bool)
      prepend_ibm_rules            = optional(bool)
      rules = list(
        object({
          name        = string
          action      = string
          destination = string
          direction   = string
          source      = string
          tcp = optional(
            object({
              port_max        = optional(number)
              port_min        = optional(number)
              source_port_max = optional(number)
              source_port_min = optional(number)
            })
          )
          udp = optional(
            object({
              port_max        = optional(number)
              port_min        = optional(number)
              source_port_max = optional(number)
              source_port_min = optional(number)
            })
          )
          icmp = optional(
            object({
              type = optional(number)
              code = optional(number)
            })
          )
        })
      )
    })
  )

  default = [
    {
      name                         = "vpc-acl"
      add_ibm_cloud_internal_rules = true
      add_vpc_connectivity_rules   = true
      prepend_ibm_rules            = true
      rules = [
        {
          name      = "allow-all-443-inbound"
          action    = "allow"
          direction = "inbound"
          tcp = {
            port_min        = 443
            port_max        = 443
            source_port_min = 443
            source_port_max = 443
          }
          destination = "0.0.0.0/0"
          source      = "0.0.0.0/0"
        },
        {
          name      = "allow-all-80-inbound"
          action    = "allow"
          direction = "inbound"
          tcp = {
            port_min        = 80
            port_max        = 80
            source_port_min = 80
            source_port_max = 80
          }
          destination = "0.0.0.0/0"
          source      = "0.0.0.0/0"
        },
        {
          name      = "allow-all-22-inbound"
          action    = "allow"
          direction = "inbound"
          tcp = {
            port_min        = 22
            port_max        = 22
            source_port_min = 22
            source_port_max = 22
          }
          destination = "0.0.0.0/0"
          source      = "0.0.0.0/0"
        },
        {
          name      = "allow-all-443-outbound"
          action    = "allow"
          direction = "outbound"
          tcp = {
            source_port_min = 443
            source_port_max = 443
            port_min        = 443
            port_max        = 443
          }
          destination = "0.0.0.0/0"
          source      = "0.0.0.0/0"
        },
        {
          name      = "allow-all-80-outbound"
          action    = "allow"
          direction = "outbound"
          tcp = {
            source_port_min = 80
            source_port_max = 80
            port_min        = 80
            port_max        = 80
          }
          destination = "0.0.0.0/0"
          source      = "0.0.0.0/0"
        },
        {
          name      = "allow-all-22-outbound"
          action    = "allow"
          direction = "outbound"
          tcp = {
            source_port_min = 22
            source_port_max = 22
            port_min        = 22
            port_max        = 22
          }
          destination = "0.0.0.0/0"
          source      = "0.0.0.0/0"
        }
      ]
    }
  ]

  validation {
    error_message = "ACL rule actions can only be `allow` or `deny`."
    condition = length(distinct(
      flatten([
        # Check through rules
        for rule in flatten([var.network_acls[*].rules]) :
        # Return false action is not valid
        false if !contains(["allow", "deny"], rule.action)
      ])
    )) == 0
  }

  validation {
    error_message = "ACL rule direction can only be `inbound` or `outbound`."
    condition = length(distinct(
      flatten([
        # Check through rules
        for rule in flatten([var.network_acls[*].rules]) :
        # Return false if direction is not valid
        false if !contains(["inbound", "outbound"], rule.direction)
      ])
    )) == 0
  }

  validation {
    error_message = "ACL rule names must match the regex pattern ^([a-z]|[a-z][-a-z0-9]*[a-z0-9])$."
    condition = length(distinct(
      flatten([
        # Check through rules
        for rule in flatten([var.network_acls[*].rules]) :
        # Return false if direction is not valid
        false if !can(regex("^([a-z]|[a-z][-a-z0-9]*[a-z0-9])$", rule.name))
      ])
    )) == 0
  }

}

##############################################################################
# Default Security Group Rules
##############################################################################

variable "security_group_rules" {
  description = "A list of security group rules to be added to the default vpc security group (default empty). [Learn more](https://github.com/terraform-ibm-modules/terraform-ibm-landing-zone-vpc/blob/main/solutions/fully-configurable/DA-types.md#security-group-rules-)."
  default     = []
  type = list(
    object({
      name       = string
      direction  = string
      remote     = optional(string)
      local      = optional(string)
      ip_version = optional(string)
      tcp = optional(
        object({
          port_max = optional(number)
          port_min = optional(number)
        })
      )
      udp = optional(
        object({
          port_max = optional(number)
          port_min = optional(number)
        })
      )
      icmp = optional(
        object({
          type = optional(number)
          code = optional(number)
        })
      )
    })
  )

  validation {
    error_message = "Security group rule direction can only be `inbound` or `outbound`."
    condition = (var.security_group_rules == null || length(var.security_group_rules) == 0) ? true : length(distinct(
      flatten([
        # Check through rules
        for rule in var.security_group_rules :
        # Return false if direction is not valid
        false if !contains(["inbound", "outbound"], rule.direction)
      ])
    )) == 0
  }

  validation {
    error_message = "Security group rule names must match the regex pattern ^([a-z]|[a-z][-a-z0-9]*[a-z0-9])$."
    condition = (var.security_group_rules == null || length(var.security_group_rules) == 0) ? true : length(distinct(
      flatten([
        # Check through rules
        for rule in var.security_group_rules :
        # Return false if direction is not valid
        false if !can(regex("^([a-z]|[a-z][-a-z0-9]*[a-z0-9])$", rule.name))
      ])
    )) == 0
  }
}

variable "clean_default_security_group_acl" {
  description = "Remove all rules from the default VPC security group and VPC ACL (less permissive)."
  type        = bool
  nullable    = false
  default     = true
}

##############################################################################
# Address Prefixes
##############################################################################

variable "address_prefixes" {
  description = "The IP range that will be defined for the VPC for a certain location. Use only with manual address prefixes. [Learn more](https://github.com/terraform-ibm-modules/terraform-ibm-landing-zone-vpc/blob/main/solutions/fully-configurable/DA-types.md#address-prefixes-)."
  type = object({
    zone-1 = optional(list(string))
    zone-2 = optional(list(string))
    zone-3 = optional(list(string))
  })
  default = {
    zone-1 = null
    zone-2 = null
    zone-3 = null
  }
  validation {
    error_message = "Keys for `use_public_gateways` must be in the order `zone-1`, `zone-2`, `zone-3`."
    condition = var.address_prefixes == null ? true : (
      (length(var.address_prefixes) == 1 && keys(var.address_prefixes)[0] == "zone-1") ||
      (length(var.address_prefixes) == 2 && keys(var.address_prefixes)[0] == "zone-1" && keys(var.address_prefixes)[1] == "zone-2") ||
      (length(var.address_prefixes) == 3 && keys(var.address_prefixes)[0] == "zone-1" && keys(var.address_prefixes)[1] == "zone-2") && keys(var.address_prefixes)[2] == "zone-3"
    )
  }
}

##############################################################################
# Add routes to VPC
##############################################################################

variable "routes" {
  description = "Allows you to specify the next hop for packets based on their destination address. [Learn more](https://github.com/terraform-ibm-modules/terraform-ibm-landing-zone-vpc/blob/main/solutions/fully-configurable/DA-types.md#routes-)."
  type = list(
    object({
      name                          = string
      route_direct_link_ingress     = optional(bool)
      route_transit_gateway_ingress = optional(bool)
      route_vpc_zone_ingress        = optional(bool)
      routes = optional(
        list(
          object({
            action      = optional(string)
            zone        = number
            destination = string
            next_hop    = string
          })
      ))
    })
  )
  default = []
}

##############################################################################
# VPC Flow Logs
##############################################################################

variable "enable_vpc_flow_logs" {
  description = "To enable VPC Flow logs, set this to true."
  type        = bool
  nullable    = false
  default     = false
}

variable "skip_vpc_cos_iam_auth_policy" {
  description = "To skip creating an IAM authorization policy that allows the VPC to access the Cloud Object Storage, set this variable to `true`. Required only if `enable_vpc_flow_logs` is set to true."
  type        = bool
  nullable    = false
  default     = false
}