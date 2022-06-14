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

variable "existing_resource_group_name" {
  type        = string
  description = "Name of the existing resource group.  Required if not creating new resource group"
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
  default = [{
    name      = "default-sgr"
    direction = "inbound"
    remote    = "10.0.0.0/8"
  }]
}

##############################################################################
