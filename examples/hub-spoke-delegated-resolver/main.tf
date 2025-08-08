##############################################################################
# Resource Group
##############################################################################

module "resource_group" {
  source  = "terraform-ibm-modules/resource-group/ibm"
  version = "1.2.1"
  # if an existing resource group is not set (null) create a new one using prefix
  resource_group_name          = var.resource_group == null ? "${var.prefix}-resource-group" : null
  existing_resource_group_name = var.resource_group
}

#############################################################################
# Delay between hub and spoke creation/destruction
#
# You can adjust these delay timings if needed.
# This block will put a slight delay between the Hub and Spoke VPC operations.
# This will help if there are resources (such as DNS resolver) that need some
# extra time to fully complete before the other VPC operations continue.
#############################################################################
resource "time_sleep" "delay_between_hub_spoke" {
  depends_on       = [module.hub_vpc]
  create_duration  = "30s"
  destroy_duration = "60s"
}

#############################################################################
# Provision VPC
#############################################################################

module "hub_vpc" {
  source            = "../../"
  resource_group_id = module.resource_group.resource_group_id
  region            = var.region
  name              = "hub"
  prefix            = "${var.prefix}-hub"
  tags              = var.resource_tags
  enable_hub        = true
  dns_zone_name     = "hnsexample.com"
  subnets = {
    zone-1 = [
      {
        name           = "subnet-a"
        cidr           = "10.10.10.0/24"
        public_gateway = true
        acl_name       = "vpc-acl"
      }
    ],
    zone-2 = [
      {
        name           = "subnet-b"
        cidr           = "10.20.10.0/24"
        public_gateway = false
        acl_name       = "vpc-acl"
      }
    ],
    zone-3 = [
      {
        name           = "subnet-c"
        cidr           = "10.30.10.0/24"
        public_gateway = false
        acl_name       = "vpc-acl"
      }
    ]
  }
}


data "ibm_iam_account_settings" "iam_account_settings" {}

module "spoke_vpc" {
  source                    = "../../"
  depends_on                = [time_sleep.delay_between_hub_spoke]
  resource_group_id         = module.resource_group.resource_group_id
  region                    = var.region
  name                      = "spoke"
  prefix                    = "${var.prefix}-spoke"
  tags                      = var.resource_tags
  hub_account_id            = data.ibm_iam_account_settings.iam_account_settings.account_id
  hub_vpc_crn               = module.hub_vpc.vpc_crn
  enable_hub_vpc_crn        = true
  resolver_type             = "delegated"
  update_delegated_resolver = var.update_delegated_resolver
  subnets = {
    zone-1 = [
      {
        name           = "subnet-a"
        cidr           = "10.40.10.0/24"
        public_gateway = true
        acl_name       = "vpc-acl"
      }
    ],
    zone-2 = [
      {
        name           = "subnet-b"
        cidr           = "10.50.10.0/24"
        public_gateway = false
        acl_name       = "vpc-acl"
      }
    ],
    zone-3 = [
      {
        name           = "subnet-c"
        cidr           = "10.60.10.0/24"
        public_gateway = false
        acl_name       = "vpc-acl"
      }
    ]
  }
}


##############################################################################
# Transit Gateway connects the 2 VPCs
##############################################################################

module "tg_gateway_connection" {
  source                    = "terraform-ibm-modules/transit-gateway/ibm"
  version                   = "2.5.1"
  transit_gateway_name      = "${var.prefix}-tg"
  region                    = var.region
  global_routing            = false
  resource_tags             = var.resource_tags
  resource_group_id         = module.resource_group.resource_group_id
  vpc_connections           = [{ vpc_crn = module.hub_vpc.vpc_crn }, { vpc_crn = module.spoke_vpc.vpc_crn }]
  classic_connections_count = 0
}
