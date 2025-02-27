variable "ibmcloud_api_key" {
  description = "APIkey that's associated with the account to provision resources."
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
  default     = "dns"
}

variable "name" {
  description = "The name of the vpc"
  type        = string
  default     = "slz-vpc"
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
  default = [
    {
      name  = "testA"
      type  = "A"
      rdata = "1.2.3.4"
      ttl   = 3600
    },
    {
      name       = "testMX"
      type       = "MX"
      rdata      = "mailserver.test.com"
      preference = 10
    },
    {
      type     = "SRV"
      name     = "testSRV"
      rdata    = "tester.com"
      priority = 100
      weight   = 100
      port     = 8000
      service  = "_sip"
      protocol = "udp"
    },
    {
      name  = "testTXT"
      type  = "TXT"
      rdata = "textinformation"
      ttl   = 900
    }
  ]
}

variable "dns_zone_name" {
  description = "The name of the DNS zone to be created."
  type        = string
  default     = "dns-example.com"
}
