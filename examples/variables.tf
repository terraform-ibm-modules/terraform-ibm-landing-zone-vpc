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
  default = "au-syd"
}

variable "prefix" {
  description = "The prefix that you would like to append to your resources"
  type        = string
  default = "test-landing-zone-vpc"
}

variable "vpc_name" {
  description = "Name for vpc. If left null, one will be generated using the prefix for this module."
  type        = string
  default     = "vpc"
}


##############################################################################
# Default Security Group Rules
##############################################################################

variable "security_group_rules" {
  description = "A list of security group rules to be added to the default vpc security group"
  default = [{
    name  = "default-sgr"
    direction = "inbound"
    remote = "10.0.0.0/8"
  }]
}


##############################################################################
