##############################################################################
# Environment Variables
##############################################################################

variable "region" {
  description = "The region to which to deploy the VPC"
  type        = string
}

variable "prefix" {
  description = "The prefix that you would like to append to your resources"
  type        = string
}

##############################################################################

##############################################################################
# Address Prefix Variables
##############################################################################

variable "address_prefixes" {
  description = "direct reference to address prefixes variable"
  type = object({
    zone-1 = optional(list(string))
    zone-2 = optional(list(string))
    zone-3 = optional(list(string))
  })
}

##############################################################################

##############################################################################
# Routes Variables
##############################################################################

variable "routes" {
  description = "direct reference to routes variable"
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
}

##############################################################################

##############################################################################
# Public Gateways
##############################################################################

variable "use_public_gateways" {
  description = "direct reference to use public gateways"
  type = object({
    zone-1 = optional(bool)
    zone-2 = optional(bool)
    zone-3 = optional(bool)
  })
}

##############################################################################

##############################################################################
# Security Group Rules
##############################################################################

variable "security_group_rules" {
  description = "direct reference to security group rules"
  type = list(
    object({
      name = string
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
}

##############################################################################

##############################################################################
# Network CIDR
##############################################################################

variable "network_cidr" {
  description = "direct reference to network cidr"
  type        = string
}

##############################################################################

##############################################################################
# Network ACLs
##############################################################################

variable "network_acls" {
  description = "direct reference to network acls"
  type = list(
    object({
      name                = string
      network_connections = optional(list(string))
      add_cluster_rules   = optional(bool)
      rules = list(
        object({
          name = string
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
}

##############################################################################

##############################################################################
# Subnets
##############################################################################

variable "public_gateways" {
  description = "ibm_is_public_gateways object"
  type = object({
    zone-1 = optional(object({
      id = string
    }))
    zone-2 = optional(object({
      id = string
    }))
    zone-3 = optional(object({
      id = string
    }))
  })
}

variable "subnets" {
  description = "direct reference to network acls"
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
}

##############################################################################
