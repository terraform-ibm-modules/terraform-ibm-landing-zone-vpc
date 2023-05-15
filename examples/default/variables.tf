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

variable "name" {
  description = "The name of the vpc"
  type        = string
  default     = "vpc"
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
  description = "Optional list of access tags to be added to the created VPC resources"
  default     = []
}

variable "enable_vpc_flow_logs" {
  type        = bool
  description = "Enable VPC Flow Logs, it will create Flow logs collector if set to true"
  default     = true
}

variable "cos_plan" {
  description = "Plan to be used for creating cloud object storage instance"
  type        = string
  default     = "standard"
  validation {
    condition     = contains(["standard", "lite"], var.cos_plan)
    error_message = "The specified cos_plan is not a valid selection!"
  }
}

variable "cos_location" {
  description = "Location of the cloud object storage instance"
  type        = string
  default     = "global"
}

variable "create_authorization_policy_vpc_to_cos" {
  description = "Set it to true if authorization policy is required for VPC to access COS"
  type        = bool
  default     = true
}

variable "address_prefixes" {
  description = "OPTIONAL - IP range that will be defined for the VPC for a certain location. Use only with manual address prefixes"
  type = object({
    zone-1 = optional(list(string))
    zone-2 = optional(list(string))
    zone-3 = optional(list(string))
  })
  default = {
    zone-1 = ["10.10.10.0/24"]
    zone-2 = ["10.20.10.0/24"]
    zone-3 = ["10.30.10.0/24"]
  }
  validation {
    error_message = "Keys for `use_public_gateways` must be in the order `zone-1`, `zone-2`, `zone-3`."
    condition     = var.address_prefixes == null ? true : (keys(var.address_prefixes)[0] == "zone-1" && keys(var.address_prefixes)[1] == "zone-2" && keys(var.address_prefixes)[2] == "zone-3")
  }
}
