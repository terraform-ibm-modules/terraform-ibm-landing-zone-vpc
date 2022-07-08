##############################################################################
# Variables
##############################################################################

variable "list" {
  description = "List of objects"
  type        = list(any)
}

variable "prefix" {
  description = "Prefix to add to map keys"
  type        = string
  default     = ""
}

variable "key_name_field" {
  description = "Key inside each object to use as the map key"
  type        = string
  default     = "name"
}

variable "lookup_field" {
  description = "Name of the field to find with lookup"
  type        = string
  default     = null
}

variable "lookup_value_regex" {
  description = "regular expression for reurned value"
  type        = string
  default     = null
}

##############################################################################
