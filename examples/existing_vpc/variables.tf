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
variable "vpc_id" {
  description = "The ID of the VPC where the VSI will be created."
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
