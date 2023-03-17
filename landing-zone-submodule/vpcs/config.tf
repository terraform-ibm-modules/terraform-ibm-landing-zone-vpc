##############################################################################
# Create Pattern Dynamic Variables
# > Values are created inside the `dynamic_modules/` module to allow them to
#   be tested
##############################################################################

module "dynamic_values" {
  source = "../dynamic_values"
  prefix = var.prefix
  region = var.region
  vpcs   = var.vpcs
}

module "dynamic_values_map" {
  source = "../dynamic_values_map"
  region = var.region
  prefix = var.prefix
  vpcs   = local.env.vpcs
}

##############################################################################


##############################################################################
# Dynamically Create Default Configuration
##############################################################################

locals {
  # If override is true, parse the JSON from override.json otherwise parse empty string
  # Empty string is used to avoid type conflicts with unary operators
  override = {
    override             = jsondecode(var.override && var.override_json_string == "" ? file("./override.json") : "{}")
    override_json_string = jsondecode(var.override_json_string == "" ? "{}" : var.override_json_string)
  }
  override_type = var.override_json_string == "" ? "override" : "override_json_string"


  ##############################################################################
  # Dynamic configuration for landing zone environment
  ##############################################################################

  config = {

    ##############################################################################
    # Deployment Configuration From Dynamic Values
    ##############################################################################

    resource_groups = module.dynamic_values.resource_groups
    vpcs            = module.dynamic_values.vpcs


    ##############################################################################
  }

  ##############################################################################
  # Compile Environment for Config output
  ##############################################################################
  env = {
    resource_groups = lookup(local.override[local.override_type], "resource_groups", local.config.resource_groups)
    vpcs            = lookup(local.override[local.override_type], "vpcs", local.config.vpcs)
  }
  ##############################################################################

  string = "\"${jsonencode(local.env)}\""
}

##############################################################################

##############################################################################
# Convert Environment to escaped readable string
##############################################################################

data "external" "format_output" {
  program = ["python3", "${path.module}/scripts/output.py", local.string]
}

##############################################################################
