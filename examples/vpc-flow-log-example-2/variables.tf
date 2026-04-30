##############################################################################
# Input Variables
##############################################################################

variable "ibmcloud_api_key" {
  description = "IBM Cloud API key"
  type        = string
  sensitive   = true
}

variable "resource_group_name" {
  type        = string
  description = "Resource Group"
  default     = "rg"
}

variable "region" {
  description = "IBM Cloud region where resources will be deployed"
  type        = string
  default     = "us-south"
}

variable "prefix" {
  description = "Prefix to be added to all resource names"
  type        = string
  default     = "test"
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "use_example_policy" {
  type        = bool
  description = "Use the policy created by the example i.e only writer role"
  default     = true
}

variable "tags" {
  description = "List of tags to apply to resources"
  type        = list(string)
  default     = []
}

variable "kms_key_name" {
  description = "Name of the KMS key for COS bucket encryption"
  type        = string
  default     = "cos-encryption-key"
}

variable "management_endpoint_type_for_bucket" {
  type        = string
  description = "value"
  default     = "direct"
}

variable "force_delete_buckets" {
  description = "Force delete COS buckets even if they contain objects"
  type        = bool
  default     = true
}

variable "clean_default_sg_acl" {
  description = "Remove all rules from the default VPC security group and ACL"
  type        = bool
  default     = false
}

variable "vpc_info" {
  description = "VPC configuration object"
  type = object({
    name         = string
    network_cidr = optional(list(string))
    use_public_gateways = optional(object({
      zone-1 = optional(bool)
      zone-2 = optional(bool)
      zone-3 = optional(bool)
    }))
    network_acls = optional(list(object({
      name                         = string
      add_ibm_cloud_internal_rules = optional(bool)
      add_vpc_connectivity_rules   = optional(bool)
      prepend_ibm_rules            = optional(bool)
      rules = list(object({
        name        = string
        action      = string
        direction   = string
        destination = string
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
    })))
    subnets = optional(object({
      zone-1 = optional(list(object({
        name           = string
        cidr           = string
        public_gateway = optional(bool)
        acl_name       = string
        no_addr_prefix = optional(bool)
      })))
      zone-2 = optional(list(object({
        name           = string
        cidr           = string
        public_gateway = optional(bool)
        acl_name       = string
        no_addr_prefix = optional(bool)
      })))
      zone-3 = optional(list(object({
        name           = string
        cidr           = string
        public_gateway = optional(bool)
        acl_name       = string
        no_addr_prefix = optional(bool)
      })))
    }))
  })
  default = {
    name         = "vpc"
    network_cidr = ["10.0.0.0/8"]
    use_public_gateways = {
      zone-1 = true
      zone-2 = false
      zone-3 = false
    }
    network_acls = [
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
    subnets = {
      zone-1 = [
        {
          name           = "subnet-a"
          cidr           = "10.10.10.0/24"
          public_gateway = true
          acl_name       = "vpc-acl"
          no_addr_prefix = false
        }
      ]
      zone-2 = [
        {
          name           = "subnet-b"
          cidr           = "10.20.10.0/24"
          public_gateway = true
          acl_name       = "vpc-acl"
          no_addr_prefix = false
        }
      ]
      zone-3 = [
        {
          name           = "subnet-c"
          cidr           = "10.30.10.0/24"
          public_gateway = false
          acl_name       = "vpc-acl"
          no_addr_prefix = false
        }
      ]
    }
  }
}
