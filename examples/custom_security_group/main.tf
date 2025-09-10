
##############################################################################
# Resource Group
##############################################################################

module "resource_group" {
  source  = "terraform-ibm-modules/resource-group/ibm"
  version = "1.3.0"
  # if an existing resource group is not set (null) create a new one using prefix
  resource_group_name          = var.resource_group == null ? "${var.prefix}-resource-group" : null
  existing_resource_group_name = var.resource_group
}

##############################################################################
# Create new VPC
# (if var.vpc_id is null, create a new VPC)
##############################################################################

module "vpc" {
  source            = "../.."
  resource_group_id = module.resource_group.resource_group_id
  region            = var.region
  prefix            = var.prefix
  name              = "sg-vpc"
  tags              = var.resource_tags
  security_group_rules = [{
    name       = "allow-all-inbound-sg"
    direction  = "inbound"
    remote     = "0.0.0.0/0" # source of the traffic. 0.0.0.0/0 traffic from all across the internet.
    local      = "0.0.0.0/0" # A CIDR block of 0.0.0.0/0 allows traffic to all local IP addresses (or from all local IP addresses, for outbound rules).
    ip_version = "ipv4"
  }]
}
