##############################################################################
# Resource Group
##############################################################################

module "resource_group" {
  source  = "terraform-ibm-modules/resource-group/ibm"
  version = "1.4.7"
  # if an existing resource group is not set (null) create a new one using prefix
  resource_group_name          = var.resource_group == null ? "${var.prefix}-resource-group" : null
  existing_resource_group_name = var.resource_group
}

#############################################################################
# Provision VPC
#############################################################################

resource "ibm_is_vpc" "example_vpc" {
  count          = var.create_vpc ? 1 : 0
  name           = "${var.prefix}-vpc"
  resource_group = module.resource_group.resource_group_id
  tags           = var.resource_tags
}

resource "ibm_is_subnet" "testacc_subnet" {
  count                    = var.create_vpc ? 1 : 0
  name                     = "${var.prefix}-subnet"
  vpc                      = ibm_is_vpc.example_vpc[0].id
  zone                     = "${var.region}-1"
  total_ipv4_address_count = 256
  resource_group           = module.resource_group.resource_group_id
}

module "postgresql_db" {
  count               = var.create_db ? 1 : 0
  source              = "terraform-ibm-modules/icd-postgresql/ibm"
  version             = "4.6.6"
  resource_group_id   = module.resource_group.resource_group_id
  name                = "${var.prefix}-vpe-pg"
  region              = var.region
  deletion_protection = false
}

## This sleep serve two purposes:
# 1. Give some extra time after postgresql db creation, and before creating the VPE targeting it. This works around the error "Service does not support VPE extensions."
# 2. Give time on deletion between the VPE destruction and the destruction of the SG that is attached to the VPE. This works around the error "Target not found"
resource "time_sleep" "sleep_time" {
  count            = var.create_db ? 1 : 0
  depends_on       = [module.postgresql_db]
  create_duration  = "180s"
  destroy_duration = "120s"
}
