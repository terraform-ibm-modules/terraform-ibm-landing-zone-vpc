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

variable "create_vpc" {
  description = "Indicates whether to create VPC."
  type        = bool
  default     = true
}

variable "prefix" {
  description = "The prefix that you would like to append to your resources"
  type        = string
  default     = "existing-slz-vpc"
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

variable "create_db" {
  description = "Indicates whether to create DB."
  type        = bool
  default     = false
}
