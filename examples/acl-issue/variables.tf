variable "ibmcloud_api_key" {
  type = string
  description = "api key"
}

variable "resource_group_id" {
  type = string 
  description = "rg id"
}

variable "account_name" {
  type = string 
  description = "account name"
}


variable "region" {
  type = string 
  description = "region"
  default = "us-south"
}


variable "vpcs" {
  description = "Map of VPC definitions to create in the IBM Cloud account. Each key is a logical VPC identifier (for example: \"mgt01\", \"test01\"). Each value should be an object supporting fields such as:"
  
  type = map(object({

    address_prefixes = object({
      zone-1 = optional(list(string))
      zone-2 = optional(list(string))
      zone-3 = optional(list(string))
    })

    #########################################################
    # Subnets
    #########################################################
    subnets = object({

      zone-1 = list(object({
        name            = string
        cidr            = string
        public_gateway  = optional(bool)
        acl_name        = string
        no_addr_prefix  = optional(bool, false) # do not automatically add address prefix for subnet
        subnet_tags     = optional(list(string), [])
      }))

      zone-2 = optional(list(object({
        name            = string
        cidr            = string
        public_gateway  = optional(bool)
        acl_name        = string
        no_addr_prefix  = optional(bool, false)
        subnet_tags     = optional(list(string), [])
      })))

      zone-3 = optional(list(object({
        name            = string
        cidr            = string
        public_gateway  = optional(bool)
        acl_name        = string
        no_addr_prefix  = optional(bool, false)
        subnet_tags     = optional(list(string), [])
      })))
    })

    #########################################################
    # Public Gateways
    #########################################################
    use_public_gateways = object({
      zone-1 = optional(bool)
      zone-2 = optional(bool)
      zone-3 = optional(bool)
    })

    #########################################################
    # Network ACL related flags
    #########################################################
    add_ibm_cloud_internal_rules = optional(bool)
    add_vpc_connectivity_rules   = optional(bool)
    prepend_ibm_rules            = optional(bool)

    #########################################################
    # ACL Rules (this is the cut part — reconstructed fully)
    #########################################################
    acl_rules = list(object({
      name        = string
      action      = string
      destination = string
      direction   = string
      source      = string

      tcp = optional(object({
        port_max        = optional(number)
        port_min        = optional(number)
        source_port_max = optional(number)
        source_port_min = optional(number)
      }))

      udp = optional(object({
        port_max        = optional(number)
        port_min        = optional(number)
        source_port_max = optional(number)
        source_port_min = optional(number)
      }))

      icmp = optional(object({
        type = optional(number)
        code = optional(number)
      }))
    }))

    #########################################################
    # Security Group Rules
    #########################################################
    security_group_rules = optional(list(object({
      name       = string
      direction  = string
      remote     = optional(string)
      local      = optional(string)
      ip_version = optional(string)
      tcp = optional(object({
        port_max = optional(number)
        port_min = optional(number)
      }))
      udp = optional(object({
        port_max = optional(number)
        port_min = optional(number)
      }))
      icmp = optional(object({
        type = optional(number)
        code = optional(number)
      }))
    })), [])

  }))
}