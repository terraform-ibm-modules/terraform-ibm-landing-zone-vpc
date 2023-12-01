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
  default     = "hs-delegated"
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

variable "update_delegated_resolver" {
  description = "If set to true, and if the vpc is configured to be a spoke for DNS resolution (enable_hub_vpc_crn or enable_hub_vpc_id set), then the spoke VPC resolver will be updated to a delegated resolver."
  type        = bool
  default     = false
}
