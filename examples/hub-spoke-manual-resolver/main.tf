##############################################################################
# Resource Group
##############################################################################

module "resource_group" {
  source  = "terraform-ibm-modules/resource-group/ibm"
  version = "1.1.4"
  # if an existing resource group is not set (null) create a new one using prefix
  resource_group_name          = var.resource_group == null ? "${var.prefix}-resource-group" : null
  existing_resource_group_name = var.resource_group
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


module "spoke_vpc" {
  source                    = "../../"
  resource_group_id         = module.resource_group.resource_group_id
  region                    = var.region
  name                      = "spoke"
  prefix                    = "${var.prefix}-spoke"
  tags                      = var.resource_tags
  hub_vpc_crn               = module.hub_vpc.vpc_crn
  enable_hub_vpc_crn        = true
  update_delegated_resolver = false
  resolver_type             = "manual"
  # Point to the custom resolver in the hub VPC
  manual_servers = [for location in module.hub_vpc.custom_resolver_hub.locations :
    {
      address = location.dns_server_ip
    }
  ]
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
  version                   = "2.3.1"
  transit_gateway_name      = "${var.prefix}-tg"
  region                    = var.region
  global_routing            = false
  resource_tags             = var.resource_tags
  resource_group_id         = module.resource_group.resource_group_id
  vpc_connections           = [module.hub_vpc.vpc_crn, module.spoke_vpc.vpc_crn]
  classic_connections_count = 0
}
