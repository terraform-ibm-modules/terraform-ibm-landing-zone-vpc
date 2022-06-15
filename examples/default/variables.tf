##############################################################################
# Required Paramaters
##############################################################################

variable "ibmcloud_api_key" {
  description = "APIkey that's associated with the account to use, set via environment variable TF_VAR_ibmcloud_api_key"
  type        = string
  sensitive   = true
}

##############################################################################
# Module Level Variables
##############################################################################

variable "region" {
  description = "The region to which to deploy the VPC"
  type        = string
  default     = "au-syd"
}

variable "prefix" {
  description = "The prefix that you would like to append to your resources"
  type        = string
  default     = "test-landing-zone-vpc"
}

variable "resource_group" {
  type        = string
  description = "An existing resource group name to use for this example, if unset a new resource group will be created"
  default     = null
}

variable "resource_tags" {
  description = "List of Tags for the resource created"
  type        = list(string)
  default     = null
}

##############################################################################
# Default Security Group Rules
##############################################################################

variable "security_group_rules" {
  description = "A list of security group rules to be added to the default vpc security group"
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
  default = [{
    name      = "default-sgr"
    direction = "inbound"
    remote    = "10.0.0.0/8"
  }]
}

##############################################################################
