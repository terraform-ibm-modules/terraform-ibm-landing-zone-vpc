# Migration Guide

## ⚠️ Deprecation Notice

In the upcoming version, the direct use of `ibm_is_vpn_gateway` resources in the root module will be **deprecated**.
These resources have been refactored into the reusable [`terraform-ibm-modules/site-to-site-vpn`](https://github.com/terraform-ibm-modules/terraform-ibm-site-to-site-vpn) module.
Users must migrate their Terraform state and update outputs to avoid resource recreation and broken references.

## Overview

This change improves maintainability and consistency by consolidating VPN gateway logic into a dedicated module.
Because resource addresses and outputs have changed, you must migrate your Terraform state and update any dependent references.


## Changes

Below changes are planned :

1. Resource address migration (using `terraform state mv` and new helper resources).
2. Output block changes (deprecation of `vpn_gateways_name` and link to new outputs).

## Resource Address Migration

### Before:

```hcl
resource "ibm_is_vpn_gateway" "vpn_gateway" {
  for_each = local.vpn_gateway_map
  ...
}
```

**Resource address:** `module.slz_vpc.ibm_is_vpn_gateway.vpn_gateway["<key>"]`

### After:

```hcl
module "vpn_gateways" {
  source                = "terraform-ibm-modules/site-to-site-vpn/ibm"
  version               = "3.0.0"
  for_each              = local.vpn_gateway_map
  resource_group_id     = each.value.resource_group == null ? var.resource_group_id : each.value.resource_group
  tags                  = var.tags

  vpn_gateway_name      = var.prefix != null ? "${var.prefix}-${each.key}" : each.key
  vpn_gateway_subnet_id = local.subnets["${local.vpc_name}-${each.value.subnet_name}"].id
  vpn_gateway_mode      = each.value.mode
}
```

**Resource address:** `module.slz_vpc.module.vpn_gateways["<key>"].ibm_is_vpn_gateway.vpn_gateway[0]`

## Migration Command

Use the terraform state mv command to migrate each gateway:

```sh
terraform state mv 'module.slz_vpc.ibm_is_vpn_gateway.vpn_gateway[<key>]' 'module.slz_vpc.module.vpn_gateways[<key>].ibm_is_vpn_gateway.vpn_gateway[0]'
```

**Example:**

If the name of `vpn_gateway` is `"vpg1"`, i.e.

```hcl
vpn_gateways = [{
      name           = "vpg1"
      subnet_name    = "subnet-a"
  }]
```

Then terraform state moved command that can be used is:

```sh
terraform state mv \
  'module.slz_vpc.ibm_is_vpn_gateway.vpn_gateway["vpg1"]' \
  'module.slz_vpc.module.vpn_gateways["vpg1"].ibm_is_vpn_gateway.vpn_gateway[0]'
```

Repeat this for all the keys in `local.vpn_gateway_map`.

## New Resources

The vpn_gateways module introduces helper resources (e.g., `time_sleep.wait_for_gateway_creation`). This is new and will be created automatically on the next apply. No migration is required.

## Output block changes

* The `site‑to‑site-vpn` module does not expose VPN names directly thus the output `vpn_gateways_name` will no longer be available.

* The existing `vpn_gateways_data` will be updated to consume the module, i.e.

``` hcl
output "vpn_gateways_data" {
  description = "Details of VPN gateways data."
  value = [
    for gateway in module.vpn_gateways : gateway
  ]
}
```
