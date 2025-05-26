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
  description = "The name of an existing resource group to provision the resources."
  default     = "Default"
}

variable "prefix" {
  type        = string
  description = "The prefix to be added to all resources created by this solution. To skip using a prefix, set this value to null or an empty string. The prefix must begin with a lowercase letter and may contain only lowercase letters, digits, and hyphens '-'. It should not exceed 16 characters, must not end with a hyphen('-'), and can not contain consecutive hyphens ('--'). Example: prod-0205-es."

  validation {
    condition = (var.prefix == null || var.prefix == "" ? true :
      alltrue([
        can(regex("^[a-z][-a-z0-9]*[a-z0-9]$", var.prefix)),
        length(regexall("--", var.prefix)) == 0
      ])
    )
    error_message = "Prefix must begin with a lowercase letter and may contain only lowercase letters, digits, and hyphens '-'. It must not end with a hyphen('-'), and cannot contain consecutive hyphens ('--')."
  }
  validation {
    condition     = length(var.prefix) <= 16
    error_message = "Prefix must not exceed 16 characters."
  }
}

variable "vpc_name" {
  default     = "vpc"
  description = "Name of the VPC. If a prefix input variable is specified, the prefix is added to the name in the `<prefix>-<name>` format."
  type        = string
}

variable "region" {
  default     = "us-south"
  description = "Region to deploy the VPC."
  type        = string
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
  description = "List of subnets for the vpc. For each item in each array, a subnet will be created. Items can be either CIDR blocks or total ipv4 addressess. Public gateways will be enabled only in zones where a gateway has been created. [Learn more](https://github.com/terraform-ibm-modules/terraform-ibm-landing-zone-vpc/blob/main/solutions/fully-configurable/DA-types.md#subnets-)."
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
      name      = string
      direction = string
      remote    = optional(string)
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
  description = "Remove all rules from the default VPC security group and VPC ACL (less permissive)"
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

variable "existing_cos_instance_crn" {
  description = "CRN of the existing COS instance. It is only required if `enable_vpc_flow_logs` is set to true and will be used to create the flow logs bucket."
  type        = string
  default     = null

  validation {
    condition     = var.enable_vpc_flow_logs ? (var.existing_cos_instance_crn != null ? true : false) : true
    error_message = "'existing_cos_instance_crn' is required if 'enable_vpc_flow_logs' is set to true."
  }
}

variable "flow_logs_cos_bucket_name" {
  description = "Name of the Cloud Object Storage bucket to be created to collect VPC flow logs."
  type        = string
  default     = "flow-logs-bucket"
}

variable "kms_encryption_enabled_bucket" {
  description = "Set to true to encrypt the Cloud Object Storage Flow Logs bucket with a KMS key. If set to true, a value must be passed for existing_flow_logs_bucket_kms_key_crn (to use that key) or existing_kms_instance_crn (to create a new key). Value cannot be set to true if enable_vpc_flow_logs is set to false."
  type        = bool
  nullable    = false
  default     = false

  validation {
    condition     = !var.enable_vpc_flow_logs ? (var.kms_encryption_enabled_bucket ? false : true) : true
    error_message = "'kms_encryption_enabled_bucket' can not be true if 'enable_vpc_flow_logs' is set to false."
  }

  validation {
    condition     = var.enable_vpc_flow_logs && var.kms_encryption_enabled_bucket ? ((var.existing_flow_logs_bucket_kms_key_crn != null || var.existing_kms_instance_crn != null) ? true : false) : true
    error_message = "Either 'existing_flow_logs_bucket_kms_key_crn' or 'existing_kms_instance_crn' is required if 'enable_vpc_flow_logs' and 'kms_encryption_enabled_bucket' are set to true."
  }
}

variable "skip_cos_kms_iam_auth_policy" {
  type        = bool
  nullable    = false
  description = "To skip creating an IAM authorization policy that allows Cloud Object Storage(COS) to access KMS key."
  default     = false
}

variable "management_endpoint_type_for_bucket" {
  description = "The type of endpoint for the IBM Terraform provider to use to manage Cloud Object Storage buckets (`public`, `private`, or `direct`). If you are using a private endpoint, make sure that you enable virtual routing and forwarding (VRF) in your account, and that the Terraform runtime can access the IBM Cloud Private network."
  type        = string
  default     = "direct"
  validation {
    condition     = contains(["public", "private", "direct"], var.management_endpoint_type_for_bucket)
    error_message = "The specified `management_endpoint_type_for_bucket` is not valid. Specify a valid type of endpoint for the IBM Terraform provider to use to manage Cloud Object Storage buckets."
  }
}

variable "cos_bucket_class" {
  type        = string
  default     = "standard"
  description = "The storage class of the newly provisioned Cloud Object Storage bucket. Specify one of the following values for the storage class: `standard`, `vault`, `cold`, `smart` (default), or `onerate_active`."
  validation {
    condition     = contains(["standard", "vault", "cold", "smart", "onerate_active"], var.cos_bucket_class)
    error_message = "Specify one of the following values for the `cos_bucket_class`: `standard`, `vault`, `cold`, `smart`, or `onerate_active`."
  }
}

variable "add_bucket_name_suffix" {
  type        = bool
  nullable    = false
  description = "Add a randomly generated suffix that is 4 characters in length, to the name of the newly provisioned Cloud Object Storage bucket. Do not use this suffix if you are passing the existing Cloud Object Storage bucket. To manage the name of the Cloud Object Storage bucket manually, use the `flow_logs_cos_bucket_name` variables."
  default     = true
}

variable "flow_logs_cos_bucket_archive_days" {
  description = "The number of days before the `archive_type` rule action takes effect for the flow logs cloud object storage bucket."
  type        = number
  default     = 90
}

variable "flow_logs_cos_bucket_archive_type" {
  description = "The storage class or archive type you want the object to transition to in the flow logs cloud object storage bucket."
  type        = string
  default     = "Glacier"
  validation {
    condition     = contains(["Glacier", "Accelerated"], var.flow_logs_cos_bucket_archive_type)
    error_message = "The specified flow_logs_cos_bucket_archive_type is not a valid selection!"
  }
}

variable "flow_logs_cos_bucket_expire_days" {
  description = "The number of days before the expire rule action takes effect for the flow logs cloud object storage bucket."
  type        = number
  default     = 366
}

variable "flow_logs_cos_bucket_enable_object_versioning" {
  description = "Set it to true if object versioning is enabled so that multiple versions of an object are retained in the flow logs cloud object storage bucket. Cannot be used if `flow_logs_cos_bucket_enable_retention` is true."
  type        = bool
  nullable    = false
  default     = false

  validation {
    condition     = var.flow_logs_cos_bucket_enable_object_versioning ? (var.flow_logs_cos_bucket_enable_retention ? false : true) : true
    error_message = "`flow_logs_cos_bucket_enable_object_versioning` cannot set true if `flow_logs_cos_bucket_enable_retention` is true."
  }
}

variable "flow_logs_cos_bucket_enable_retention" {
  description = "Set to true to enable retention for the flow logs cloud object storage bucket."
  type        = bool
  nullable    = false
  default     = false
}

variable "flow_logs_cos_bucket_default_retention_days" {
  description = "The number of days that an object can remain unmodified in the flow logs cloud object storage bucket."
  type        = number
  default     = 90
}

variable "flow_logs_cos_bucket_maximum_retention_days" {
  description = "The maximum number of days that an object can be kept unmodified in the flow logs cloud object storage."
  type        = number
  default     = 350
}

variable "flow_logs_cos_bucket_minimum_retention_days" {
  description = "The minimum number of days that an object must be kept unmodified in the flow logs cloud object storage."
  type        = number
  default     = 90
}

variable "flow_logs_cos_bucket_enable_permanent_retention" {
  description = "Whether permanent retention status is enabled for the flow logs cloud object storage bucket. [Learn more](https://cloud.ibm.com/docs/cloud-object-storage?topic=cloud-object-storage-immutable)."
  type        = bool
  nullable    = false
  default     = false
}

###############################################################################################################
# KMS
###############################################################################################################

variable "existing_flow_logs_bucket_kms_key_crn" {
  type        = string
  default     = null
  description = "The CRN of the existing root key of key management service (KMS) that is used to encrypt the flow logs Cloud Object Storage bucket. If no value is set for this variable, specify a value for the `existing_kms_instance_crn` variable to create a key ring and key."
}

variable "existing_kms_instance_crn" {
  type        = string
  default     = null
  description = "The CRN of the existing key management service (KMS) that is used to create keys for encrypting the flow logs Cloud Object Storage bucket. Used to create a new KMS key unless an existing key is passed using the `existing_flow_logs_bucket_kms_key_crn` input."
}

variable "kms_endpoint_type" {
  type        = string
  description = "The type of endpoint to use for communicating with the KMS. Possible values: `public`, `private`. Applies only if `existing_flow_logs_bucket_kms_key_crn` is not specified."
  default     = "private"
  validation {
    condition     = can(regex("public|private", var.kms_endpoint_type))
    error_message = "Valid values for the `kms_endpoint_type_value` are `public` or `private`."
  }
}

variable "kms_key_ring_name" {
  type        = string
  default     = "flow-logs-cos-key-ring"
  description = "The name of the key ring to create for the Cloud Object Storage bucket key. If an existing key is used, this variable is not required. If the prefix input variable is passed, the name of the key ring is prefixed to the value in the `<prefix>-value` format."
}

variable "kms_key_name" {
  type        = string
  default     = "flow-logs-cos-key"
  description = "The name of the key to encrypt the flow logs Cloud Object Storage bucket. If an existing key is used, this variable is not required. If the prefix input variable is passed, the name of the key is prefixed to the value in the `<prefix>-value` format."
}

variable "ibmcloud_kms_api_key" {
  type        = string
  description = "The IBM Cloud API key that can create a root key and key ring in the key management service (KMS) instance. If not specified, the 'ibmcloud_api_key' variable is used. Specify this key if the instance in `existing_kms_instance_crn` is in an account that's different from the Cloud Object Storage instance. Leave this input empty if the same account owns both instances."
  sensitive   = true
  default     = null
}

##############################################################################
# Optional VPC Variables
##############################################################################

variable "default_network_acl_name" {
  description = "Name of the Default ACL. If null, a name will be automatically generated."
  type        = string
  default     = null
}

variable "default_security_group_name" {
  description = "Name of the Default Security Group. If null, a name will be automatically generated."
  type        = string
  default     = null
}

variable "default_routing_table_name" {
  description = "Name of the Default Routing Table. If null, a name will be automatically generated."
  type        = string
  default     = null
}

##############################################################################
# VPN Gateways
##############################################################################

variable "vpn_gateways" {
  description = "List of VPN Gateways to create. [Learn more](https://github.com/terraform-ibm-modules/terraform-ibm-landing-zone-vpc/blob/main/solutions/fully-configurable/DA-types.md#vpn-gateways-)."
  nullable    = false
  type = list(
    object({
      name           = string
      subnet_name    = string # Do not include prefix, use same name as in `var.subnets`
      mode           = optional(string)
      resource_group = optional(string)
      access_tags    = optional(list(string), [])
    })
  )

  default = []
}

##############################################################################
# VPE Gateways
##############################################################################

variable "vpe_gateway_cloud_services" {
  description = "The list of cloud services used to create endpoint gateways. If `vpe_name` is not specified in the list, VPE names are created in the format `<prefix>-<vpc_name>-<service_name>`. [Learn more](https://github.com/terraform-ibm-modules/terraform-ibm-landing-zone-vpc/blob/main/solutions/fully-configurable/DA-types.md#vpe-gateway-cloud-services-)."
  type = set(object({
    service_name                 = string
    vpe_name                     = optional(string), # Full control on the VPE name. If not specified, the VPE name will be computed based on prefix, vpc name and service name.
    allow_dns_resolution_binding = optional(bool, false)
  }))
  default = []
}

variable "vpe_gateway_cloud_service_by_crn" {
  description = "The list of cloud service CRNs used to create endpoint gateways. Use this list to identify services that are not supported by service name in the `cloud_services` variable. For a list of supported services, see [VPE-enabled services](https://cloud.ibm.com/docs/vpc?topic=vpc-vpe-supported-services). If `service_name` is not specified, the CRN is used to find the name. If `vpe_name` is not specified in the list, VPE names are created in the format `<prefix>-<vpc_name>-<service_name>`. [Learn more](https://github.com/terraform-ibm-modules/terraform-ibm-landing-zone-vpc/blob/main/solutions/fully-configurable/DA-types.md#vpe-gateway-cloud-service-by-crn-)."
  type = set(
    object({
      crn                          = string
      vpe_name                     = optional(string) # Full control on the VPE name. If not specified, the VPE name will be computed based on prefix, vpc name and service name.
      service_name                 = optional(string) # Name of the service used to compute the name of the VPE. If not specified, the service name will be obtained from the crn.
      allow_dns_resolution_binding = optional(bool, true)
    })
  )
  default = []
}

variable "vpe_gateway_service_endpoints" {
  description = "Service endpoints to use to create endpoint gateways. Can be `public`, or `private`."
  type        = string
  default     = "private"

  validation {
    error_message = "Service endpoints can only be `public` or `private`."
    condition     = contains(["public", "private"], var.vpe_gateway_service_endpoints)
  }
}

variable "vpe_gateway_security_group_ids" {
  description = "List of security group ids to attach to each endpoint gateway."
  type        = list(string)
  default     = null # Let this default value be null instead of []. Provider issue - https://github.com/IBM-Cloud/terraform-provider-ibm/issues/4546
}

variable "vpe_gateway_reserved_ips" {
  description = "Map of existing reserved IP names and values. Leave this value as default if you want to create new reserved ips, this value is used when a user passes their existing reserved ips created here and not attempt to recreate those. [Learn more](https://github.com/terraform-ibm-modules/terraform-ibm-landing-zone-vpc/blob/main/solutions/fully-configurable/DA-types.md#reserved-ips-)."
  type = object({
    name = optional(string) # reserved ip name
  })
  default = {}
}
