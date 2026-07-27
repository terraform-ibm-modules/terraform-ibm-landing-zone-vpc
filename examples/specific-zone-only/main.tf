##############################################################################
# Resource Group
##############################################################################

module "resource_group" {
  source  = "terraform-ibm-modules/resource-group/ibm"
  version = "1.6.1"
  # if an existing resource group is not set (null) create a new one using prefix
  resource_group_name          = var.resource_group == null ? "${var.prefix}-resource-group" : null
  existing_resource_group_name = var.resource_group
}

#############################################################################
# Provision VPC
#############################################################################

module "slz_vpc" {
  source                  = "../../"
  resource_group_id       = module.resource_group.resource_group_id
  region                  = var.region
  name                    = var.name
  prefix                  = var.prefix
  resource_tags           = var.resource_tags
  incremental_rule_update = true
  subnets = {
    zone-1 = []
    zone-2 = [
      {
        name           = "subnet-a"
        cidr           = "10.10.10.0/24"
        public_gateway = true
        acl_name       = "${var.prefix}-acl"
      }
    ]
  }
  # Must be in the order
  use_public_gateways = {
    zone-1 = false
    zone-2 = true
    zone-3 = false
  }

  network_acls = [{
    name                         = "${var.prefix}-acl"
    add_ibm_cloud_internal_rules = false
    add_vpc_connectivity_rules   = false
    prepend_ibm_rules            = false
    rules = [{
      name        = "inbound"
      action      = "allow"
      source      = "0.0.0.0/0"
      destination = "0.0.0.0/0"
      direction   = "inbound"
      },
      {
        name        = "outbound"
        action      = "allow"
        source      = "0.0.0.0/0"
        destination = "0.0.0.0/0"
        direction   = "outbound"
      },
      {
        name        = "abcd-telnet"
        action      = "deny"
        source      = "0.0.0.0/0"
        destination = "10.10.10.0/24"
        direction   = "inbound"
        protocol    = "tcp"
        port_min    = 23
        port_max    = 23
      },
      {
        name        = "deny-ftp"
        action      = "deny"
        source      = "0.0.0.0/0"
        destination = "10.10.10.0/24"
        direction   = "inbound"
        protocol    = "tcp"
        port_min    = 20
        port_max    = 21
        # },
        # {
        #   name        = "allow-custom-app-port"
        #   action      = "allow"
        #   source      = "10.20.0.0/24"
        #   destination = "10.10.10.0/24"
        #   direction   = "inbound"
        #   protocol    = "tcp"
        #   port_min    = 8080
        #   port_max    = 8080
        # },
        # {
        #   name        = "allow-port-range"
        #   action      = "allow"
        #   source      = "10.10.10.0/24"
        #   destination = "10.20.0.0/24"
        #   direction   = "outbound"
        #   protocol    = "tcp"
        #   port_min    = 30000
        #   port_max    = 32767 # NodePort range for Kubernetes
      }
    ]
    }
  ]
}
