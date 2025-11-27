locals {
  prefix = var.prefix != null ? (trimspace(var.prefix) != "" ? "${var.prefix}-" : "") : ""
}

##############################################################################
# Resource Group
##############################################################################

module "resource_group" {
  source                       = "terraform-ibm-modules/resource-group/ibm"
  version                      = "1.4.0"
  existing_resource_group_name = var.existing_resource_group_name
}


#############################################################################
# Provision cloud object storage and bucket
#############################################################################

module "cos" {
  count                  = var.enable_vpc_flow_logs ? 1 : 0
  source                 = "terraform-ibm-modules/cos/ibm"
  version                = "10.5.8"
  resource_group_id      = module.resource_group.resource_group_id
  region                 = var.region
  cos_instance_name      = "${var.prefix}-cos"
  cos_tags               = var.resource_tags
  bucket_name            = "${var.prefix}-bucket"
  kms_encryption_enabled = false
}

###########################################################################
# NETWORK ACL PROFILES
###########################################################################

locals {
  acl_profiles = {
    open = [
      {
        name                         = "${local.prefix}acl"
        add_ibm_cloud_internal_rules = false
        add_vpc_connectivity_rules   = false
        prepend_ibm_rules            = false
        rules = [
          {
            name        = "allow-all-inbound"
            action      = "allow"
            direction   = "inbound"
            source      = "0.0.0.0/0"
            destination = "0.0.0.0/0"
          },
          {
            name        = "allow-all-outbound"
            action      = "allow"
            direction   = "outbound"
            source      = "0.0.0.0/0"
            destination = "0.0.0.0/0"
          }
        ]
      }
    ]
    common = [
      {
        name                         = "${local.prefix}acl"
        add_ibm_cloud_internal_rules = true
        add_vpc_connectivity_rules   = true
        prepend_ibm_rules            = true
        rules = [
          {
            name        = "allow-ssh"
            action      = "allow"
            direction   = "inbound"
            source      = "0.0.0.0/0"
            destination = "0.0.0.0/0"
            tcp         = { port_min = 22, port_max = 22 }
          },
          {
            name        = "allow-https"
            action      = "allow"
            direction   = "inbound"
            source      = "0.0.0.0/0"
            destination = "0.0.0.0/0"
            tcp         = { port_min = 443, port_max = 443 }
          },
          {
            name        = "allow-http"
            action      = "allow"
            direction   = "inbound"
            source      = "0.0.0.0/0"
            destination = "0.0.0.0/0"
            tcp         = { port_min = 80, port_max = 80 }
          }
        ]
      }
    ]
    ibm-internal = [
      {
        name                         = "${local.prefix}acl"
        add_ibm_cloud_internal_rules = true
        add_vpc_connectivity_rules   = true
        prepend_ibm_rules            = true
        rules                        = []
      }
    ]
    closed = [
      {
        name                         = "${local.prefix}acl"
        add_ibm_cloud_internal_rules = false
        add_vpc_connectivity_rules   = false
        prepend_ibm_rules            = false
        rules                        = []
      }
    ]
  }
  network_acls = lookup(local.acl_profiles, var.network_acls, local.acl_profiles["common"])
}

#############################################################################
# VPC
#############################################################################

module "vpc" {
  source            = "../../"
  resource_group_id = module.resource_group.resource_group_id
  region            = var.region
  create_vpc        = true
  name              = var.vpc_name
  prefix            = local.prefix != "" ? trimspace(var.prefix) : null
  tags              = var.resource_tags
  access_tags       = var.access_tags
  subnets = {
    zone-1 = [
      {
        name           = "${local.prefix}subnet-a"
        cidr           = "10.10.10.0/24"
        public_gateway = true
        acl_name       = "${local.prefix}acl"
        no_addr_prefix = false
      }
    ]
    zone-2 = [
      {
        name           = "${local.prefix}subnet-b"
        cidr           = "10.20.10.0/24"
        public_gateway = true
        acl_name       = "${local.prefix}acl"
        no_addr_prefix = false
      }
    ]
    zone-3 = [
      {
        name           = "${local.prefix}subnet-c"
        cidr           = "10.30.10.0/24"
        public_gateway = true
        acl_name       = "${local.prefix}acl"
        no_addr_prefix = false
      }
    ]
  }
  network_acls                           = local.network_acls
  enable_vpc_flow_logs                   = var.enable_vpc_flow_logs
  create_authorization_policy_vpc_to_cos = !var.skip_vpc_cos_iam_auth_policy
  existing_cos_instance_guid             = var.enable_vpc_flow_logs ? module.cos[0].cos_instance_guid : null
  existing_storage_bucket_name           = var.enable_vpc_flow_logs ? module.cos[0].bucket_name : null
}
