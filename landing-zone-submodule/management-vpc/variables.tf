variable "ibmcloud_api_key" {
  description = "APIkey that's associated with the account to provision resources to"
  type        = string
  sensitive   = true
}

variable "region" {
  description = "The region to which to deploy the VPC"
  type        = string
  default     = "au-syd"
}

variable "prefix" {
  description = "The prefix that you would like to append to your resources"
  type        = string
  default     = "management"
}

variable "resource_group" {
  type        = string
  description = "An existing resource group name to use for this example, if unset a new resource group will be created"
  default     = null
}

variable "tags" {
  description = "List of tags to apply to resources created by this module."
  type        = list(string)
  default     = []
}


#############################################################################
# VPC variables
#############################################################################

variable "network_cidr" {
  description = "Network CIDR for the VPC. This is used to manage network ACL rules for cluster provisioning."
  type        = string
  default     = "10.0.0.0/8"
}

variable "classic_access" {
  description = "Optionally allow VPC to access classic infrastructure network"
  type        = bool
  default     = null
}

variable "use_manual_address_prefixes" {
  description = "Optionally assign prefixes to VPC manually. By default this is false, and prefixes will be created along with subnets"
  type        = bool
  default     = true
}

variable "default_network_acl_name" {
  description = "Override default ACL name"
  type        = string
  default     = null
}

variable "default_security_group_name" {
  description = "Override default VPC security group name"
  type        = string
  default     = null
}

variable "default_routing_table_name" {
  description = "Override default VPC routing table name"
  type        = string
  default     = null
}

variable "default_security_group_rules" {
  description = "Override default security group rules"
  type = list(
    object({
      name      = string
      direction = string
      remote    = string
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

  default = []
}

variable "address_prefixes" {
  description = "Use `address_prefixes` only if `use_manual_address_prefixes` is true otherwise prefixes will not be created. Use only if you need to manage prefixes manually."
  type = object({
    zone-1 = optional(list(string))
    zone-2 = optional(list(string))
    zone-3 = optional(list(string))
  })

  default = null
}

variable "network_acls" {
  description = "List of network ACLs to create with VPC"
  type = list(
    object({
      name              = string
      add_cluster_rules = optional(bool)
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
      "add_cluster_rules" : true,
      "name" : "management-acl",
      "rules" : [
        {
          "action" : "allow",
          "destination" : "10.0.0.0/8",
          "direction" : "inbound",
          "name" : "allow-ibm-inbound",
          "source" : "161.26.0.0/16"
        },
        {
          "action" : "allow",
          "destination" : "10.0.0.0/8",
          "direction" : "inbound",
          "name" : "allow-all-network-inbound",
          "source" : "10.0.0.0/8"
        },
        {
          "action" : "allow",
          "destination" : "0.0.0.0/0",
          "direction" : "outbound",
          "name" : "allow-all-outbound",
          "source" : "0.0.0.0/0"
        }
      ]
    }
  ]
}

variable "use_public_gateways" {
  description = "For each `zone` that is set to `true`, a public gateway will be created in that zone"
  type = object({
    zone-1 = optional(bool)
    zone-2 = optional(bool)
    zone-3 = optional(bool)
  })
  default = {
    zone-1 = false
    zone-2 = false
    zone-3 = false
  }
}


variable "subnets" {
  description = "Object for subnets to be created in each zone, each zone can have any number of subnets"
  type = object({
    zone-1 = list(object({
      name           = string
      cidr           = string
      public_gateway = optional(bool)
      acl_name       = string
    }))
    zone-2 = list(object({
      name           = string
      cidr           = string
      public_gateway = optional(bool)
      acl_name       = string
    }))
    zone-3 = list(object({
      name           = string
      cidr           = string
      public_gateway = optional(bool)
      acl_name       = string
    }))
  })
  default = {
    "zone-1" : [
      {
        "acl_name" : "management-acl",
        "cidr" : "10.10.10.0/24",
        "name" : "vsi-zone-1",
        "public_gateway" : false
      },
      {
        "acl_name" : "management-acl",
        "cidr" : "10.10.20.0/24",
        "name" : "vpe-zone-1",
        "public_gateway" : false
      },
      {
        "acl_name" : "management-acl",
        "cidr" : "10.10.30.0/24",
        "name" : "vpn-zone-1",
        "public_gateway" : false
      }
    ],
    "zone-2" : [
      {
        "acl_name" : "management-acl",
        "cidr" : "10.20.10.0/24",
        "name" : "vsi-zone-2",
        "public_gateway" : false
      },
      {
        "acl_name" : "management-acl",
        "cidr" : "10.20.20.0/24",
        "name" : "vpe-zone-2",
        "public_gateway" : false
      }
    ],
    "zone-3" : [
      {
        "acl_name" : "management-acl",
        "cidr" : "10.30.10.0/24",
        "name" : "vsi-zone-3",
        "public_gateway" : false
      },
      {
        "acl_name" : "management-acl",
        "cidr" : "10.30.20.0/24",
        "name" : "vpe-zone-3",
        "public_gateway" : false
      }
    ]
  }
}


#############################################################################
# Variables for COS and Flow Logs
#############################################################################

variable "enable_vpc_flow_logs" {
  type        = bool
  description = "Enable VPC Flow Logs, it will create Flow logs collector if set to true"
  default     = true
}

variable "cos_plan" {
  description = "Plan to be used for creating cloud object storage instance"
  type        = string
  default     = "standard"
  validation {
    condition     = contains(["standard", "lite"], var.cos_plan)
    error_message = "The specified cos_plan is not a valid selection!"
  }
}

variable "cos_location" {
  description = "Location of the cloud object storage instance"
  type        = string
  default     = "global"
}

variable "create_authorization_policy_vpc_to_cos" {
  description = "Set it to true if authorization policy is required for VPC to access COS"
  type        = bool
  default     = true
}