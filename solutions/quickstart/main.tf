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
# SECURITY GROUP RULES
###########################################################################

locals {
  public_security_group_rules = var.network_profile == "unrestricted" ? [
    {
      name      = "allow-all-inbound"
      direction = "inbound"
      remote    = "0.0.0.0/0"
      tcp       = null
    },
    {
      name      = "allow-all-outbound"
      direction = "outbound"
      remote    = "0.0.0.0/0"
      tcp       = null
    }
    ] : var.network_profile == "public_web_services" ? [
    {
      name      = "allow-ssh"
      direction = "inbound"
      remote    = "0.0.0.0/0"
      tcp       = { port_min = 22, port_max = 22 }
    },
    {
      name      = "allow-http"
      direction = "inbound"
      remote    = "0.0.0.0/0"
      tcp       = { port_min = 80, port_max = 80 }
    },
    {
      name      = "allow-https"
      direction = "inbound"
      remote    = "0.0.0.0/0"
      tcp       = { port_min = 443, port_max = 443 }
    }
  ] : []
}

###########################################################################
# NETWORK ACL PROFILES
###########################################################################

locals {
  acl_profiles = {

    unrestricted = [
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

    public_web_services = [
      {
        name                         = "${local.prefix}acl"
        add_ibm_cloud_internal_rules = true
        add_vpc_connectivity_rules   = true
        prepend_ibm_rules            = true

        rules = [
          {
            name        = "allow-inbound-ssh"
            action      = "allow"
            direction   = "inbound"
            source      = "0.0.0.0/0"
            destination = "0.0.0.0/0"
            tcp = {
              port_min = 22
              port_max = 22
            }
          },
          {
            name        = "allow-inbound-http"
            action      = "allow"
            direction   = "inbound"
            source      = "0.0.0.0/0"
            destination = "0.0.0.0/0"
            tcp = {
              port_min = 80
              port_max = 80
            }
          },
          {
            name        = "allow-inbound-https"
            action      = "allow"
            direction   = "inbound"
            source      = "0.0.0.0/0"
            destination = "0.0.0.0/0"
            tcp = {
              port_min = 443
              port_max = 443
            }
          },
          {
            name        = "allow-outbound-ssh"
            action      = "allow"
            direction   = "outbound"
            source      = "0.0.0.0/0"
            destination = "0.0.0.0/0"
            tcp = {
              source_port_min = 22
              source_port_max = 22
            }
          },
          {
            name        = "allow-outbound-http"
            action      = "allow"
            direction   = "outbound"
            source      = "0.0.0.0/0"
            destination = "0.0.0.0/0"
            tcp = {
              source_port_min = 80
              source_port_max = 80
            }
          },
          {
            name        = "allow-outbound-https"
            action      = "allow"
            direction   = "outbound"
            source      = "0.0.0.0/0"
            destination = "0.0.0.0/0"
            tcp = {
              source_port_min = 443
              source_port_max = 443
            }
          }
        ]
      }
    ],

    private_only = [
      {
        name                         = "${local.prefix}acl"
        add_ibm_cloud_internal_rules = true
        add_vpc_connectivity_rules   = true
        prepend_ibm_rules            = true
        rules                        = []
      }
    ]

    isolated = [
      {
        name                         = "${local.prefix}acl"
        add_ibm_cloud_internal_rules = false
        add_vpc_connectivity_rules   = false
        prepend_ibm_rules            = false
        rules                        = []
      }
    ]
  }

  network_acls         = lookup(local.acl_profiles, var.network_profile, local.acl_profiles["public_web_services"])
  clean_default_sg_acl = contains(["private_only", "isolated"], var.network_profile)
  allow_public_gateway = contains(["unrestricted", "public_web_services"], var.network_profile)
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
        public_gateway = local.allow_public_gateway
        acl_name       = "${local.prefix}acl"
        no_addr_prefix = false
      }
    ]
    zone-2 = [
      {
        name           = "${local.prefix}subnet-b"
        cidr           = "10.20.10.0/24"
        public_gateway = local.allow_public_gateway
        acl_name       = "${local.prefix}acl"
        no_addr_prefix = false
      }
    ]
    zone-3 = [
      {
        name           = "${local.prefix}subnet-c"
        cidr           = "10.30.10.0/24"
        public_gateway = local.allow_public_gateway
        acl_name       = "${local.prefix}acl"
        no_addr_prefix = false
      }
    ]
  }
  network_acls         = local.network_acls
  security_group_rules = local.public_security_group_rules
  clean_default_sg_acl = local.clean_default_sg_acl
  use_public_gateways = {
    zone-1 = local.allow_public_gateway
    zone-2 = local.allow_public_gateway
    zone-3 = local.allow_public_gateway
  }
  enable_vpc_flow_logs                   = var.enable_vpc_flow_logs
  create_authorization_policy_vpc_to_cos = !var.skip_vpc_cos_iam_auth_policy
  existing_cos_instance_guid             = var.enable_vpc_flow_logs ? module.cos[0].cos_instance_guid : null
  existing_storage_bucket_name           = var.enable_vpc_flow_logs ? module.cos[0].bucket_name : null
}
