##############################################################################
# Module Level Variables
##############################################################################

variable "name" {
  description = "The string to use for the naming of VPC, when var.create_vpc is true. This string also use for the naming of VPC resources."
  type        = string
  default     = "dev"
}

variable "dns_binding_name" {
  description = "The name to give the provisioned VPC DNS resolution binding. Only used if 'enable_hub' is false and either of 'enable_hub_vpc_id' or 'enable_hub_vpc_crn' is set."
  type        = string
  default     = null
}

variable "dns_instance_name" {
  description = "The name to give the provisioned DNS instance. Only used if 'enable_hub' is true and both of 'skip_custom_resolver_hub_creation' or 'use_existing_dns_instance' are false."
  type        = string
  default     = null
}

variable "dns_custom_resolver_name" {
  description = "The name to give the provisioned DNS custom resolver instance. Only used if 'enable_hub' is true and 'skip_custom_resolver_hub_creation'is false."
  type        = string
  default     = null
}

variable "routing_table_name" {
  description = "The name to give the provisioned Routing table."
  type        = string
  default     = null
}

variable "public_gateway_name" {
  description = "The name to give the provisioned VPC Public Gateway."
  type        = string
  default     = null
}

variable "vpc_flow_logs_name" {
  description = "The name to give the provisioned VPC flow logs."
  type        = string
  default     = null
}

variable "create_vpc" {
  description = "Indicates whether user wants to use an existing vpc or create a new one. Set it to true to create a new vpc"
  type        = bool
  default     = true
}

variable "existing_vpc_id" {
  description = "The ID of the existing vpc. Required if 'create_vpc' is false."
  type        = string
  default     = null
}

variable "resource_group_id" {
  description = "The resource group ID where the VPC to be created"
  type        = string
}

variable "region" {
  description = "The region to which to deploy the VPC"
  type        = string
}

variable "prefix" {
  description = "The value that you would like to prefix to the name of the resources provisioned by this module. Explicitly set to null if you do not wish to use a prefix."
  type        = string
  default     = null
}

variable "tags" {
  description = "List of Tags for the resource created"
  type        = list(string)
  default     = null
}

variable "access_tags" {
  type        = list(string)
  description = "A list of access tags to apply to the VPC resources created by the module. For more information, see https://cloud.ibm.com/docs/account?topic=account-access-tags-tutorial."
  default     = []

  validation {
    condition = alltrue([
      for tag in var.access_tags : can(regex("[\\w\\-_\\.]+:[\\w\\-_\\.]+", tag)) && length(tag) <= 128
    ])
    error_message = "Tags must match the regular expression \"[\\w\\-_\\.]+:[\\w\\-_\\.]+\". For more information, see https://cloud.ibm.com/docs/account?topic=account-tag&interface=ui#limits."
  }
}

##############################################################################

##############################################################################
# Optional VPC Variables
##############################################################################

variable "network_cidrs" {
  description = "List of Network CIDRs for the VPC. This is used to manage network ACL rules for cluster provisioning."
  type        = list(string)
  default     = ["10.0.0.0/8"]
}

variable "classic_access" {
  description = "OPTIONAL - Classic Access to the VPC"
  type        = bool
  default     = false
}

variable "default_network_acl_name" {
  description = "OPTIONAL - Name of the Default ACL. If null, a name will be automatically generated"
  type        = string
  default     = null
}

variable "default_security_group_name" {
  description = "OPTIONAL - Name of the Default Security Group. If null, a name will be automatically generated"
  type        = string
  default     = null
}

variable "default_routing_table_name" {
  description = "OPTIONAL - Name of the Default Routing Table. If null, a name will be automatically generated"
  type        = string
  default     = null
}

variable "address_prefixes" {
  description = "OPTIONAL - IP range that will be defined for the VPC for a certain location. Use only with manual address prefixes"
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


##############################################################################
# Network ACLs
##############################################################################

variable "network_acls" {
  description = "The list of ACLs to create. Provide at least one rule for each ACL."
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


##############################################################################
# Public Gateways
##############################################################################

variable "use_public_gateways" {
  description = "Create a public gateway in any of the three zones with `true`."
  type = object({
    zone-1 = optional(bool)
    zone-2 = optional(bool)
    zone-3 = optional(bool)
  })
  default = {
    zone-1 = true
    zone-2 = false
    zone-3 = false
  }

  validation {
    error_message = "Keys for `use_public_gateways` must be in the order `zone-1`, `zone-2`, `zone-3`."
    condition = (
      (length(var.use_public_gateways) == 1 && keys(var.use_public_gateways)[0] == "zone-1") ||
      (length(var.use_public_gateways) == 2 && keys(var.use_public_gateways)[0] == "zone-1" && keys(var.use_public_gateways)[1] == "zone-2") ||
      (length(var.use_public_gateways) == 3 && keys(var.use_public_gateways)[0] == "zone-1" && keys(var.use_public_gateways)[1] == "zone-2") && keys(var.use_public_gateways)[2] == "zone-3"
    )
  }
}

##############################################################################


##############################################################################
# Subnets
##############################################################################

variable "subnets" {
  description = "List of subnets for the vpc. For each item in each array, a subnet will be created. Items can be either CIDR blocks or total ipv4 addressess. Public gateways will be enabled only in zones where a gateway has been created"
  type = object({
    zone-1 = list(object({
      name           = string
      cidr           = string
      public_gateway = optional(bool)
      acl_name       = string
    }))
    zone-2 = optional(list(object({
      name           = string
      cidr           = string
      public_gateway = optional(bool)
      acl_name       = string
    })))
    zone-3 = optional(list(object({
      name           = string
      cidr           = string
      public_gateway = optional(bool)
      acl_name       = string
    })))
  })

  default = {
    zone-1 = [
      {
        name           = "subnet-a"
        cidr           = "10.10.10.0/24"
        public_gateway = true
        acl_name       = "vpc-acl"
      }
    ],
    zone-2 = [
      {
        name           = "subnet-b"
        cidr           = "10.20.10.0/24"
        public_gateway = true
        acl_name       = "vpc-acl"
      }
    ],
    zone-3 = [
      {
        name           = "subnet-c"
        cidr           = "10.30.10.0/24"
        public_gateway = false
        acl_name       = "vpc-acl"
      }
    ]
  }

  validation {
    error_message = "Keys for `subnets` must be in the order `zone-1`, `zone-2`, `zone-3`. "
    condition = (
      (length(var.subnets) == 1 && keys(var.subnets)[0] == "zone-1") ||
      (length(var.subnets) == 2 && keys(var.subnets)[0] == "zone-1" && keys(var.subnets)[1] == "zone-2") ||
      (length(var.subnets) == 3 && keys(var.subnets)[0] == "zone-1" && keys(var.subnets)[1] == "zone-2") && keys(var.subnets)[2] == "zone-3"
    )
  }
}

variable "create_subnets" {
  description = "Indicates whether user wants to use existing subnets or create new. Set it to true to create new subnets."
  type        = bool
  default     = true
}

variable "existing_subnet_ids" {
  description = "The IDs of the existing subnets. Required if 'create_subnets' is false."
  type        = list(string)
  default     = null
}

##############################################################################


##############################################################################
# Default Security Group Rules
##############################################################################

variable "security_group_rules" {
  description = "A list of security group rules to be added to the default vpc security group (default empty)"
  default     = []
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

variable "clean_default_sg_acl" {
  description = "Remove all rules from the default VPC security group and VPC ACL (less permissive)"
  type        = bool
  default     = false
}

##############################################################################


##############################################################################
# Add routes to VPC
##############################################################################

variable "routes" {
  description = "OPTIONAL - Allows you to specify the next hop for packets based on their destination address"
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

##############################################################################
# VPC Flow Logs Variables
##############################################################################

variable "enable_vpc_flow_logs" {
  description = "Flag to enable vpc flow logs. If true, flow log collector will be created"
  type        = bool
  default     = false
}

variable "create_authorization_policy_vpc_to_cos" {
  description = "Create authorisation policy for VPC to access COS. Set as false if authorization policy exists already"
  type        = bool
  default     = false
}

variable "existing_cos_instance_guid" {
  description = "GUID of the COS instance to create Flow log collector"
  type        = string
  default     = null
}

variable "existing_storage_bucket_name" {
  description = "Name of the COS bucket to collect VPC flow logs"
  type        = string
  default     = null
}

variable "is_flow_log_collector_active" {
  description = "Indicates whether the collector is active. If false, this collector is created in inactive mode."
  type        = bool
  default     = true
}

##############################################################################

##############################################################################
# VPC Hub-Spoke support
##############################################################################

variable "enable_hub" {
  description = "Indicates whether this VPC is enabled as a DNS name resolution hub."
  type        = bool
  default     = false
}

variable "enable_hub_vpc_id" {
  description = "Indicates whether Hub VPC ID is passed."
  type        = bool
  default     = false
}

variable "hub_vpc_id" {
  description = "Indicates the id of the hub VPC for DNS resolution. See https://cloud.ibm.com/docs/vpc?topic=vpc-hub-spoke-model. Mutually exclusive with hub_vpc_crn."
  type        = string
  default     = null
}

variable "enable_hub_vpc_crn" {
  description = "Indicates whether Hub VPC CRN is passed."
  type        = bool
  default     = false
}

variable "hub_vpc_crn" {
  description = "Indicates the crn of the hub VPC for DNS resolution. See https://cloud.ibm.com/docs/vpc?topic=vpc-hub-spoke-model. Mutually exclusive with hub_vpc_id."
  type        = string
  default     = null
}

variable "update_delegated_resolver" {
  description = "If set to true, and if the vpc is configured to be a spoke for DNS resolution (enable_hub_vpc_crn or enable_hub_vpc_id set), then the spoke VPC resolver will be updated to a delegated resolver."
  type        = bool
  default     = false
}

variable "skip_custom_resolver_hub_creation" {
  description = "Indicates whether to skip the configuration of a custom resolver in the hub VPC. Only relevant if enable_hub is set to true."
  type        = bool
  default     = false
}

variable "existing_dns_instance_id" {
  description = "Id of an existing dns instance in which the custom resolver is created. Only relevant if enable_hub is set to true."
  type        = string
  default     = null
}

variable "use_existing_dns_instance" {
  description = "Whether to use an existing dns instance. If true, existing_dns_instance_id must be set."
  type        = bool
  default     = false
}

variable "resolver_type" {
  description = "Resolver type. Can be system or manual. For delegated resolver type, see the update_delegated_resolver variable instead. "
  type        = string
  default     = null
  validation {
    condition = anytrue([
      var.resolver_type == null,
      var.resolver_type == "system",
      var.resolver_type == "manual",
    ])
    error_message = "var.resolver_type either be null, or set to the string 'system' or 'manual'."
  }
}

variable "manual_servers" {
  description = "The DNS server addresses to use for the VPC, replacing any existing servers. All the entries must either have a unique zone_affinity, or not have a zone_affinity."
  type = list(object({
    address       = string
    zone_affinity = optional(string)
  }))
  default = []
}

variable "dns_location" {
  description = "The target location or environment for the DNS instance created to host the custom resolver in a hub-spoke DNS resolution topology. Only used if enable_hub is true and skip_custom_resolver_hub_creation is false (defaults). "
  type        = string
  default     = "global"
}

variable "dns_plan" {
  description = "The plan for the DNS resource instance created to host the custom resolver in a hub-spoke DNS resolution topology. Only used if enable_hub is true and skip_custom_resolver_hub_creation is false (defaults)."
  type        = string
  default     = "standard-dns"
  validation {
    condition = anytrue([
      var.dns_plan == "standard-dns",
      var.dns_plan == "free-plan",
    ])
    error_message = "var.dns_plan can either be standard-dns or free-plan."
  }
}
