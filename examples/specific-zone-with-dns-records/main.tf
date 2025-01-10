##############################################################################
# Resource Group
##############################################################################

module "resource_group" {
  source  = "terraform-ibm-modules/resource-group/ibm"
  version = "1.1.6"
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
  name              = var.name
  prefix            = var.prefix
  tags              = var.resource_tags
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
      }
    ]
    }
  ]
  # enable_hub                = true
  # use_existing_dns_instance = true
  # existing_dns_instance_id  = var.existing_dns_instance_id
  # dns_records               = var.dns_records
  # dns_zone_name             = var.dns_zone_name
  # dns_zone_description = var.dns_zone_description
  # dns_zone_label       = var.dns_zone_label
}
