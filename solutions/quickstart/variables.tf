##############################################################################
# Input Variables
##############################################################################

variable "ibmcloud_api_key" {
  type        = string
  description = "The IBM Cloud API key to deploy resources."
  sensitive   = true
}

variable "provider_visibility" {
  description = "Set the visibility value for the IBM terraform provider. Supported values are `public`, `private`, `public-and-private`. [Learn more](https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs/guides/custom-service-endpoints)."
  type        = string
  default     = "private"

  validation {
    condition     = contains(["public", "private", "public-and-private"], var.provider_visibility)
    error_message = "Invalid visibility option. Allowed values are 'public', 'private', or 'public-and-private'."
  }
}

variable "existing_resource_group_name" {
  type        = string
  description = "The name of an existing resource group to provision the resources. [Learn more](https://cloud.ibm.com/docs/account?topic=account-rgs&interface=ui#create_rgs) about how to create a resource group."
  default     = "Default"
}

variable "prefix" {
  type        = string
  nullable    = true
  description = "The prefix to add to all resources that this solution creates (e.g `prod`, `test`, `dev`). To skip using a prefix, set this value to null or an empty string. [Learn more](https://terraform-ibm-modules.github.io/documentation/#/prefix.md)."

  validation {
    # - null and empty string is allowed
    # - Must not contain consecutive hyphens (--): length(regexall("--", var.prefix)) == 0
    # - Starts with a lowercase letter: [a-z]
    # - Contains only lowercase letters (a–z), digits (0–9), and hyphens (-)
    # - Must not end with a hyphen (-): [a-z0-9]
    condition = (var.prefix == null || var.prefix == "" ? true :
      alltrue([
        can(regex("^[a-z][-a-z0-9]*[a-z0-9]$", var.prefix)),
        length(regexall("--", var.prefix)) == 0
      ])
    )
    error_message = "Prefix must begin with a lowercase letter and may contain only lowercase letters, digits, and hyphens '-'. It must not end with a hyphen('-'), and cannot contain consecutive hyphens ('--')."
  }

  validation {
    # must not exceed 16 characters in length
    condition     = var.prefix == null || var.prefix == "" ? true : length(var.prefix) <= 16
    error_message = "Prefix must not exceed 16 characters."
  }
}

variable "vpc_name" {
  default     = "vpc"
  description = "Name of the VPC. If a prefix input variable is specified, the prefix is added to the name in the `<prefix>-<name>` format."
  type        = string
}

variable "region" {
  type        = string
  description = "The region to provision all resources in."
  default     = "us-south"
}

variable "resource_tags" {
  type        = list(string)
  description = "The list of tags to add to the VPC instance."
  default     = []
}

variable "access_tags" {
  type        = list(string)
  description = "The list of access tags to add to the VPC instance."
  default     = []
}

##############################################################################
# Network ACLs
##############################################################################

variable "network_profile" {
  description = "Predefined network ACL profile to control inbound and outbound traffic behavior. [Learn more](https://github.com/terraform-ibm-modules/terraform-ibm-landing-zone-vpc/blob/main/solutions/quickstart/DA-types.md) about each profile."
  type        = string
  default     = "standard"
  validation {
    condition     = contains(["open", "standard", "ibm-cloud-private-backbone", "closed"], var.network_profile)
    error_message = "Valid value for network_profile is not provided."
  }
}
##############################################################################
# VPC Flow Logs
##############################################################################

variable "enable_vpc_flow_logs" {
  description = "When set to true, enables VPC Flow Logs and automatically creates a Cloud Object Storage (COS) instance and bucket to store the flow log data."
  type        = bool
  nullable    = false
  default     = false
}

variable "skip_vpc_cos_iam_auth_policy" {
  description = "To skip creating an IAM authorization policy that allows the VPC to access the Cloud Object Storage, set this variable to `true`. Required only if `enable_vpc_flow_logs` is set to true."
  type        = bool
  nullable    = false
  default     = false
}
