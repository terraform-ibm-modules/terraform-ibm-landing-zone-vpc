variable "ibmcloud_api_key" {
  description = "APIkey that's associated with the account to provision resources to"
  type        = string
  sensitive   = true
}

variable "region" {
  description = "The region to which to deploy the VPC"
  type        = string
}

variable "vpc_id" {
  description = "The ID of the VPC where the VSI will be created."
  type        = string
}

variable "public_gateway_name" {
  description = "The name of the public gateway"
  type        = string
}

variable "subnet_ids" {
  description = "The ID of the VPC where the VSI will be created."
  type        = list(string)
}

variable "existing_resource_group_name" {
  type        = string
  description = "An existing resource group name to use for this example."
}

variable "name" {
  description = "The string is used as a prefix for the naming of VPC resources."
  type        = string
}

variable "dns_records" {
  description = "List of DNS records to create"
  type = list(object({
    name       = string
    type       = string
    rdata      = string
    ttl        = optional(number)
    preference = optional(number)
    priority   = optional(number)
    port       = optional(number)
    protocol   = optional(string)
    service    = optional(string)
    weight     = optional(number)
  }))
}

variable "dns_zone_name" {
  description = "The name of the DNS zone to be created."
  type        = string
}
