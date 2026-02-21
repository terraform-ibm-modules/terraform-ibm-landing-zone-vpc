
##############################################################################
# Resource Group
##############################################################################

module "resource_group" {
  source  = "terraform-ibm-modules/resource-group/ibm"
  version = "1.4.8"
  # if an existing resource group is not set (null) create a new one using prefix
  resource_group_name          = var.resource_group == null ? "${var.prefix}-resource-group" : null
  existing_resource_group_name = var.resource_group
}

#############################################################################
# Provision VPC
#############################################################################

module "slz_vpc" {
  source            = "../../"
  resource_group_id = module.resource_group.resource_group_id
  region            = var.region
  name              = "vpc"
  prefix            = var.prefix
  tags              = var.resource_tags
  subnets = {
    zone-1 = [
      {
        name           = "subnet-a"
        cidr           = "10.10.10.0/24"
        public_gateway = true
        acl_name       = "vpc-acl"
      }
    ]
  }
  # The following Security Group rule allows all inbound traffic from anywhere (0.0.0.0/0) using any protocol for ipv4.
  # Note: When no protocol is specified (tcp, udp, icmp), the rule applies to all protocols.
  #  security_group_rules = [{
  #    name       = "allow-all-inbound-sg"
  #    direction  = "inbound"
  #    remote     = "0.0.0.0/0" # source of the traffic. 0.0.0.0/0 traffic from all across the internet.
  #    local      = "0.0.0.0/0" # A CIDR block of 0.0.0.0/0 allows traffic to all local IP addresses (or from all local IP addresses, for outbound rules).
  #    ip_version = "ipv4"
  #  }]

  security_group_rules = [
    {
      name       = "allow-all-inbound-ssh"
      direction  = "inbound"
      remote     = "0.0.0.0/0"
      local      = "0.0.0.0/0"
      ip_version = "ipv4"
      tcp = {
        port_min = 22
        port_max = 22
      }
    },
    {
      name       = "allow-all-inbound-http"
      direction  = "inbound"
      remote     = "0.0.0.0/0"
      local      = "0.0.0.0/0"
      ip_version = "ipv4"
      tcp = {
        port_min = 80
        port_max = 80
      }
    },
    {
      name       = "allow-all-inbound-https"
      direction  = "inbound"
      remote     = "0.0.0.0/0"
      local      = "0.0.0.0/0"
      ip_version = "ipv4"
      tcp = {
        port_min = 443
        port_max = 443
      }
    },
    {
      name       = "allow-all-inbound-dns-udp"
      direction  = "inbound"
      remote     = "0.0.0.0/0"
      local      = "0.0.0.0/0"
      ip_version = "ipv4"
      udp = {
        port_min = 53
        port_max = 53
      }
    },
    {
      name       = "allow-all-inbound-icmp-echo"
      direction  = "inbound"
      remote     = "0.0.0.0/0"
      local      = "0.0.0.0/0"
      ip_version = "ipv4"
      icmp = {
        type = 8
        code = 0
      }
    }
  ]
}
