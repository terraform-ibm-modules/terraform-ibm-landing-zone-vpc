# VPN Gateway migration steps

## VPN Gateway changes in v9.0.0

* Starting with version `v9.0.0`, direct use of the VPN gateway in the main setup will be **removed**.
* Instead of defining the VPN gateway resources, reference the [`terraform-ibm-modules/site-to-site-vpn`](https://github.com/terraform-ibm-modules/terraform-ibm-site-to-site-vpn) module.
* Users must migrate their Terraform state and update outputs to avoid resource recreation and broken references.

## Overview

This change improves maintainability and consistency by consolidating VPN gateway logic into a dedicated module.
Because resource addresses and outputs have changed, you must migrate your Terraform state and update any dependent references.

This release introduces the following changes:

1. Resource address migration (using `terraform state mv` and new helper resources).
2. Output block changes (deprecation of `vpn_gateways_name` and link to new outputs).

## Resource Address Migration

The module to create VPN gateways can now be used as shown in the below example.

```hcl
module "vpn_gateways" {
  source                = "terraform-ibm-modules/site-to-site-vpn/ibm"
  version               = "3.0.4" # Replace with the version of site to site VPN Module
  for_each              = {
    vpn_gw_1 = {
      resource_group_id     = "xxXXxxXXxXxXXXXxxXxxxXXXXxXXXXX" # Replace with your resource group id.
      name      = "gateway-1"
      mode      = "route"
      subnet_id = "xxXXxxXXxXxXXXXxxXxxxXXXXxXXXXX" # Replace with the subnet id where VPN Gateway will be created.
    }
    vpn_gw_2 = {
      resource_group_id     = "xxXXxxXXxXxXXXXxxXxxxXXXXxXXXXX" # Replace with your resource group id.
      name      = "gateway-2"
      mode      = "policy"
      subnet_id = "xxXXxxXXxXxXXXXxxXxxxXXXXxXXXXX" # Replace with the subnet id where VPN Gateway will be created.
    }
  }
  resource_group_id     = each.value.resource_group_id
  vpn_gateway_name      = each.value.name
  vpn_gateway_subnet_id = each.value.subnet_id
  vpn_gateway_mode      = each.value.mode
}
```

**Resource address (current):** `module.slz_vpc.ibm_is_vpn_gateway.vpn_gateway["<gateway-name>"]`
**Resource address (after migration):** `module.slz_vpc.module.vpn_gateways["<gateway-name>"]`.ibm_is_vpn_gateway.vpn_gateway[0]`

## Migration Command

If you are upgrading an existing environment, you need to tell Terraform that the resource has moved so it doesn’t try to recreate it.

**Option 1: Using moved block :**

```hcl
moved {
  from = module.slz_vpc.ibm_is_vpn_gateway.vpn_gateway["gateway-1"]
  to   = module.slz_vpc.module.vpn_gateways["gateway-1"].ibm_is_vpn_gateway.vpn_gateway[0]
}
```

**Option 2: Using terraform state mv (manual alternative):**

Use the terraform state mv command to migrate each gateway:

```sh
terraform state mv 'module.slz_vpc.ibm_is_vpn_gateway.vpn_gateway[<gateway-name>]' 'module.slz_vpc.module.vpn_gateways[<gateway-name>].ibm_is_vpn_gateway.vpn_gateway[0]'
```

**Example:**

If the name of `vpn_gateway` is `gateway-1`, i.e.

```hcl
vpn_gateways = [{
      name           = "gateway-1"
      subnet_name    = "subnet-a"
  }]
```

Then terraform state moved command that can be used is:

```sh
terraform state mv 'module.slz_vpc.ibm_is_vpn_gateway.vpn_gateway["gateway-1"]' 'module.slz_vpc.module.vpn_gateways["gateway-1"].ibm_is_vpn_gateway.vpn_gateway[0]'
```

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
