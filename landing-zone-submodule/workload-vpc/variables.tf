variable "region" {
  description = "The region to which to deploy the VPC"
  type        = string
  default     = "au-syd"
}

variable "prefix" {
  description = "The prefix that you would like to append to your resources"
  type        = string
  default     = "workload"
}

variable "resource_group_id" {
  description = "The resource group ID where the VPC to be created"
  type        = string
}

variable "tags" {
  description = "List of tags to apply to resources created by this module."
  type        = list(string)
  default     = []
}

variable "access_tags" {
  type        = list(string)
  description = "Optional list of access tags to add to the VPC resources that are created"
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

variable "clean_default_security_group" {
  description = "Remove all rules from the default VPC security group (less permissive)"
  type        = bool
  default     = false
}

variable "clean_default_acl" {
  description = "Remove all rules from the default VPC ACL (less permissive)"
  type        = bool
  default     = false
}

variable "ibmcloud_api_visibility" {
  description = "IBM Cloud API visibility used by scripts run in this module. Must be 'public', 'private', or 'public-and-private'"
  type        = string
  default     = "public"

  validation {
    error_message = "IBM Cloud API visibility must be either 'public', 'private', or 'public-and-private'"
    condition     = (var.ibmcloud_api_visibility == "public") || (var.ibmcloud_api_visibility == "private") || (var.ibmcloud_api_visibility == "public-and-private")
  }
}

variable "ibmcloud_api_key" {
  description = "IBM Cloud API Key that will be used for authentication in scripts run in this module. Only required if certain options are chosen, such as the 'clean_default_*' variables being 'true'."
  type        = string
  sensitive   = true
  default     = null
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
      name                         = "workload-acl"
      add_ibm_cloud_internal_rules = true
      add_vpc_connectivity_rules   = true
      prepend_ibm_rules            = true
      rules = [
        ## The below rules may be added to easily provide network connectivity for a loadbalancer
        ## Note that opening 0.0.0.0/0 is not FsCloud compliant
        # {
        #   name      = "allow-all-443-inbound"
        #   action    = "allow"
        #   direction = "inbound"
        #   tcp = {

        #     port_min = 443
        #     port_max = 443
        #     source_port_min = 1024
        #     source_port_max = 65535
        #   }
        #   destination = "0.0.0.0/0"
        #   source      = "0.0.0.0/0"
        # },
        # {
        #   name      = "allow-all-443-outbound"
        #   action    = "allow"
        #   direction = "outbound"
        #   tcp = {
        #     source_port_min = 443
        #     source_port_max = 443
        #     port_min = 1024
        #     port_max = 65535
        #   }
        #   destination = "0.0.0.0/0"
        #   source      = "0.0.0.0/0"
        # }
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
        "acl_name" : "workload-acl",
        "cidr" : "10.40.10.0/24",
        "name" : "vsi-zone-1",
        "public_gateway" : false
      },
      {
        "acl_name" : "workload-acl",
        "cidr" : "10.40.20.0/24",
        "name" : "vpe-zone-1",
        "public_gateway" : false
      }
    ],
    "zone-2" : [
      {
        "acl_name" : "workload-acl",
        "cidr" : "10.50.10.0/24",
        "name" : "vsi-zone-2",
        "public_gateway" : false
      },
      {
        "acl_name" : "workload-acl",
        "cidr" : "10.50.20.0/24",
        "name" : "vpe-zone-2",
        "public_gateway" : false
      }
    ],
    "zone-3" : [
      {
        "acl_name" : "workload-acl",
        "cidr" : "10.60.10.0/24",
        "name" : "vsi-zone-3",
        "public_gateway" : false
      },
      {
        "acl_name" : "workload-acl",
        "cidr" : "10.60.20.0/24",
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
  default     = false
}

variable "create_authorization_policy_vpc_to_cos" {
  description = "Set it to true if authorization policy is required for VPC to access COS"
  type        = bool
  default     = false
}

variable "existing_cos_instance_guid" {
  description = "GUID of the COS instance to create Flow log collector"
  type        = string
  default     = null
}

variable "existing_cos_bucket_name" {
  description = "Name of the COS bucket to collect VPC flow logs"
  type        = string
  default     = null
}
