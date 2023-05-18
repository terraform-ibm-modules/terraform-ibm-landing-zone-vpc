variable "ibmcloud_api_key" {
  description = "APIkey that's associated with the account to provision resources to"
  type        = string
  sensitive   = true
}

variable "region" {
  description = "The region to which to deploy the VPC"
  type        = string
  default     = "us-south"
}

variable "prefix" {
  description = "The prefix that you would like to append to your resources"
  type        = string
  default     = "test-landing-zone"
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

variable "access_tags" {
  type        = list(string)
  description = "Optional list of access tags to add to the VPC resources that are created"
  default     = []
}

##############################################################################
# VPC flow logs variables
##############################################################################

variable "enable_vpc_flow_logs" {
  type        = bool
  description = "Enable VPC Flow Logs, it will create Flow logs collector if set to true"
  default     = true
}

variable "create_authorization_policy_vpc_to_cos" {
  description = "Set it to true if authorization policy is required for VPC to access COS"
  type        = bool
  default     = true
}
