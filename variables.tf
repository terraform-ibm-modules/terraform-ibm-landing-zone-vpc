##############################################################################
# Module Level Variables
##############################################################################

variable "create_vpc" {
  description = "Indicates whether user wants to use an existing vpc or create a new one. Set it to true to create a new vpc"
  type        = bool
  default     = true

  validation {
    condition     = !(var.create_vpc == false && var.existing_vpc_id == null)
    error_message = "You must either enable 'create_vpc' or provide 'existing_vpc_id', but not both or neither."
  }

  validation {
    condition     = !(var.create_vpc == true && var.create_subnets == false)
    error_message = "You must create subnets while creating a VPC. Hence if 'create_vpc' is true, then 'create_subnets' should be true."
  }
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
# Naming Variables
##############################################################################

variable "prefix" {
  description = "The value that you would like to prefix to the name of the resources provisioned by this module. Explicitly set to null if you do not wish to use a prefix. This value is ignored if using one of the optional variables for explicit control over naming."
  type        = string
  default     = null
}

variable "name" {
  description = "Used for the naming of the VPC (if create_vpc is set to true), as well as in the naming for any resources created inside the VPC (unless using one of the optional variables for explicit control over naming)."
  type        = string
}

variable "dns_binding_name" {
  description = "The name to give the provisioned VPC DNS resolution binding. If not set, the module generates a name based on the `prefix` and `name` variables."
  type        = string
  default     = null
}

variable "dns_instance_name" {
  description = "The name to give the provisioned DNS instance. If not set, the module generates a name based on the `prefix` and `name` variables."
  type        = string
  default     = null
}

variable "dns_custom_resolver_name" {
  description = "The name to give the provisioned DNS custom resolver instance. If not set, the module generates a name based on the `prefix` and `name` variables."
  type        = string
  default     = null
}

variable "routing_table_name" {
  description = "The name to give the provisioned routing tables. If not set, the module generates a name based on the `prefix` and `name` variables."
  type        = string
  default     = null
}

variable "public_gateway_name" {
  description = "The name to give the provisioned VPC public gateways. If not set, the module generates a name based on the `prefix` and `name` variables."
  type        = string
  default     = null
}

variable "vpc_flow_logs_name" {
  description = "The name to give the provisioned VPC flow logs. If not set, the module generates a name based on the `prefix` and `name` variables."
  type        = string
  default     = null
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

  validation {
    error_message = "Each network ACL rule must specify at most one protocol (tcp, udp, or icmp), or omit all protocol blocks to allow all protocols. Found a rule with multiple protocols defined. To allow multiple protocols, create separate rules - one for each protocol. For example, instead of one rule with both tcp and udp blocks, create two rules: one with tcp only and another with udp only."
    condition = length(distinct(
      flatten([
        # Check through rules
        for rule in flatten([var.network_acls[*].rules]) :
        # Count how many protocols are specified (non-null)
        # Return false if more than one protocol is specified
        false if length([
          for protocol in [rule.tcp, rule.udp, rule.icmp] :
          protocol if protocol != null
        ]) > 1
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
    zone-2 = true
    zone-3 = true
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
  description = "List of subnets for the vpc. For each item in each array, a subnet will be created. Items can be either CIDR blocks or total ipv4 addresses. Public gateways will be enabled only in zones where a gateway has been created"
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

variable "existing_subnets" {
  description = "The detail of the existing subnets and required mappings to other resources. Required if 'create_subnets' is false."
  type = list(object({
    id             = string
    public_gateway = optional(bool, false)
  }))
  default  = []
  nullable = false

  validation {
    condition = (
      (var.create_subnets && length(var.existing_subnets) == 0) ||
      (!var.create_subnets && length(var.existing_subnets) > 0)
    )
    error_message = "You must either set 'create_subnets' to true and leave 'existing_subnets' empty, or set 'create_subnets' to false and provide a non-empty list for 'existing_subnets'."
  }
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

  validation {
    condition     = !(var.clean_default_sg_acl && var.security_group_rules != null && length(var.security_group_rules) > 0)
    error_message = "var.clean_default_sg_acl is true and var.security_group_rules are not empty, which are in direct conflict. If you want to clean the default VPC Security Group, you must not pass security_group_rules."
  }

  validation {
    error_message = "Each security group rule must specify at most one protocol (tcp, udp, or icmp), or omit all protocol blocks to allow all protocols. Found a rule with multiple protocols defined. To allow multiple protocols, create separate rules - one for each protocol. For example, instead of one rule with both tcp and udp blocks, create two rules: one with tcp only and another with udp only."
    condition = (var.security_group_rules == null || length(var.security_group_rules) == 0) ? true : length(distinct(
      flatten([
        for rule in var.security_group_rules :
        # Count how many protocols are specified (non-null)
        # Return false if more than one protocol is specified
        false if length([
          for protocol in [rule.tcp, rule.udp, rule.icmp] :
          protocol if protocol != null
        ]) > 1
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

  validation {
    condition = (
      !var.enable_vpc_flow_logs ||
      (
        var.create_authorization_policy_vpc_to_cos
        ? (var.existing_cos_instance_guid != null && var.existing_storage_bucket_name != null)
        : (var.existing_storage_bucket_name != null)
      )
    )
    error_message = "To enable VPC Flow Logs, provide COS Bucket name. If you're creating an authorization policy then also provide COS instance GUID."
  }
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

variable "skip_spoke_auth_policy" {
  description = "Set to true to skip the creation of an authorization policy between the DNS resolution spoke and hub, only enable this if a policy already exists between these two VPCs. See https://cloud.ibm.com/docs/vpc?topic=vpc-vpe-dns-sharing-s2s-auth&interface=ui for more details."
  type        = bool
  default     = false

  validation {
    condition = (
      var.hub_account_id != null ||
      var.skip_spoke_auth_policy ||
      var.enable_hub ||
      !(var.enable_hub_vpc_id || var.enable_hub_vpc_crn)
    )
    error_message = "var.hub_account_id must be set when var.skip_spoke_auth_policy is false and either var.enable_hub_vpc_id or var.enable_hub_vpc_crn is true and enable_hub is false."
  }
}

variable "hub_account_id" {
  description = "ID of the hub account for DNS resolution, required if 'skip_spoke_auth_policy' is false."
  type        = string
  default     = null
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

  validation {
    condition     = !(var.hub_vpc_id != null && var.hub_vpc_crn != null)
    error_message = "The inputs 'hub_vpc_id' and 'hub_vpc_crn' are mutually exclusive. Only one of them can be set at a time."
  }

  validation {
    condition     = !(var.enable_hub_vpc_id && var.hub_vpc_id == null)
    error_message = "The input 'hub_vpc_id' must be provided when 'enable_hub_vpc_id' is set to true."
  }
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

  validation {
    condition     = !(var.enable_hub_vpc_crn && var.hub_vpc_crn == null)
    error_message = "The input 'hub_vpc_crn' must be provided when 'enable_hub_vpc_crn' is set to true."
  }
}

variable "update_delegated_resolver" {
  description = "If set to true, and if the vpc is configured to be a spoke for DNS resolution (enable_hub_vpc_crn or enable_hub_vpc_id set), then the spoke VPC resolver will be updated to a delegated resolver."
  type        = bool
  default     = false

  validation {
    condition     = !(var.update_delegated_resolver == true && var.resolver_type != "delegated")
    error_message = "If var.update_delegated_resolver is true then var.resolver_type must be set to 'delegated'."
  }
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
  description = "Resolver type. Can be system or manual or delegated."
  type        = string
  default     = null
  validation {
    condition = anytrue([
      var.resolver_type == null,
      var.resolver_type == "system",
      var.resolver_type == "manual",
      var.resolver_type == "delegated"
    ])
    error_message = "`resolver_type` can either be null, or set to the string 'system', 'delegated' or 'manual'."
  }
}

variable "manual_servers" {
  description = "The DNS server addresses to use for the VPC, replacing any existing servers. All the entries must either have a unique zone_affinity, or not have a zone_affinity."
  type = list(object({
    address       = string
    zone_affinity = optional(string)
  }))
  default = []

  validation {
    condition     = !(var.resolver_type == "manual" && length(var.manual_servers) == 0)
    error_message = "The input 'manual_servers' must be set when 'resolver_type' is 'manual'."
  }
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
    error_message = "`dns_plan` can either be standard-dns or free-plan."
  }
}

variable "dns_zones" {
  description = "List of the DNS zone to be created."
  type = list(object({
    name        = string
    description = optional(string)
    label       = optional(string, "dns-zone")
  }))
  nullable = false
  default  = []

  validation {
    condition     = var.enable_hub && !var.skip_custom_resolver_hub_creation ? length(var.dns_zones) != 0 : true
    error_message = "dns_zones must not be empty list when enable_hub is true and skip_custom_resolver_hub_creation is false."
  }

  validation {
    condition = alltrue([
      for zone in var.dns_zones :
      !contains([
        "ibm.com",
        "softlayer.com",
        "bluemix.net",
        "softlayer.local",
        "mybluemix.net",
        "networklayer.com",
        "ibmcloud.com",
        "pdnsibm.net",
        "appdomain.cloud",
        "compass.cobaltiron.com"
      ], zone.name)
    ])
    error_message = "The specified DNS zone name is not permitted. Please choose a different domain name. [Learn more](https://cloud.ibm.com/docs/dns-svcs?topic=dns-svcs-managing-dns-zones&interface=ui#restricted-dns-zone-names)"
  }
}

variable "dns_records" {
  description = "List of DNS records to be created."
  type = map(list(object({
    name       = string
    type       = string
    ttl        = number
    rdata      = string
    preference = optional(number, null)
    service    = optional(string, null)
    protocol   = optional(string, null)
    priority   = optional(number, null)
    weight     = optional(number, null)
    port       = optional(number, null)
  })))
  nullable = false
  default  = {}

  validation {
    condition     = length(var.dns_records) == 0 || alltrue([for k in keys(var.dns_records) : contains([for zone in var.dns_zones : zone.name], k)])
    error_message = "The keys of 'dns_records' must match DNS names in 'dns_zones'."
  }

  validation {
    condition     = length(var.dns_records) == 0 || alltrue(flatten([for key, record in var.dns_records : [for value in record : (contains(["A", "AAAA", "CNAME", "MX", "PTR", "TXT", "SRV"], value.type))]]))
    error_message = "Invalid domain resource record type is provided. Allowed values are 'A', 'AAAA', 'CNAME', 'MX', 'PTR', 'TXT', 'SRV'."
  }

  validation {
    condition = length(var.dns_records) == 0 || alltrue(flatten([
      for key, record in var.dns_records : [for value in record : (
        value.type != "SRV" || (
          value.protocol != null && value.port != null &&
          value.service != null && value.priority != null && value.weight != null
        )
        )
    ]]))
    error_message = "Invalid SRV record configuration. For 'SRV' records, 'protocol' , 'service', 'priority', 'port' and 'weight' values must be provided."
  }
  validation {
    condition = length(var.dns_records) == 0 || alltrue(flatten([
      for key, record in var.dns_records : [for value in record : (
        value.type != "MX" || value.preference != null
        )
    ]]))
    error_message = "Invalid MX record configuration. For 'MX' records, value for 'preference' must be provided."
  }
}

##############################################################################
# VPN Gateways
##############################################################################

variable "vpn_gateways" {
  description = "[DEPRECATED] List of VPN gateways to create. For more information please refer the [migration guide](https://github.com/terraform-ibm-modules/terraform-ibm-landing-zone-vpc/blob/main/docs/migration_guide.md)."
  nullable    = false
  type = list(
    object({
      name           = string
      subnet_name    = string # Do not include prefix, use same name as in `var.subnets`
      mode           = optional(string, "route")
      resource_group = optional(string)
      access_tags    = optional(list(string), [])
    })
  )
  default = []
}
