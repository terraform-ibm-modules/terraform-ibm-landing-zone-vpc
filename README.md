# IBM Secure Landing Zone VPC module

[![Build Status](https://github.com/terraform-ibm-modules/terraform-ibm-landing-zone-vpc/actions/workflows/ci.yml/badge.svg)](https://github.com/terraform-ibm-modules/terraform-ibm-landing-zone-vpc/actions/workflows/ci.yml)
[![semantic-release](https://img.shields.io/badge/%20%20%F0%9F%93%A6%F0%9F%9A%80-semantic--release-e10079.svg)](https://github.com/semantic-release/semantic-release)
[![pre-commit](https://img.shields.io/badge/pre--commit-enabled-brightgreen?logo=pre-commit&logoColor=white)](https://github.com/pre-commit/pre-commit)

This module creates the following IBM Cloud&reg; Virtual Private Cloud (VPC) network components:

- VPC
- Public gateways
- Subnets
- Network ACLs
- VPN gateways
- VPN gateway connections

![vpc-module](./.docs/vpc-module.png)

## VPC

This module creates a VPC in a resource group, and supports classic access. The VPC and components are specified in the [main.tf](main.tf) file.

---

## Public gateways

You can optionally create public gateways in the VPC in each of the three zones of the VPC's region.

---

## Network ACLs

You can create any number of network ACLs with any number of rules. By default, VPC network ACLs can have no more than 25 rules.

---

## Subnets

You can create up to three zones in the [subnet.tf](subnet.tf) file. You can optionally attach public gateways to each subnet. And you can provide an ACL as a parameter to each subnet if the ACL is created by the module.

### Address prefixes

A CIDR block is created in the VPC for each subnet that is provisioned.

### Subnets variable

The following example shows the `subnets` variable.

```terraform
object({
    zone-1 = list(object({
      name           = string
      cidr           = string
      acl_name       = string
      public_gateway = optional(bool)
    }))
    zone-2 = list(object({
      name           = string
      cidr           = string
      acl_name       = string
      public_gateway = optional(bool)
    }))
    zone-3 = list(object({
      name           = string
      cidr           = string
      acl_name       = string
      public_gateway = optional(bool)
    }))
  })
```

`zone-1`, `zone-2`, and `zone-3` are lists, but are converted to objects before the resources are provisioned. The conversion ensures that the addition or deletion of subnets affects only the added or deleted subnets, as shown in the following example.

```terraform
module.subnets.ibm_is_subnet.subnet["gcat-multizone-subnet-a"]
module.subnets.ibm_is_subnet.subnet["gcat-multizone-subnet-b"]
module.subnets.ibm_is_subnet.subnet["gcat-multizone-subnet-c"]
module.subnets.ibm_is_vpc_address_prefix.subnet_prefix["gcat-multizone-subnet-a"]
module.subnets.ibm_is_vpc_address_prefix.subnet_prefix["gcat-multizone-subnet-b"]
module.subnets.ibm_is_vpc_address_prefix.subnet_prefix["gcat-multizone-subnet-c"]
```

---

## VPN gateways

You can create any number of VPN gateways on your subnets by using the `vpn_gateways` variable. For more information about VPN gateways on VPC, see [About site-to-site VPN gateways](https://cloud.ibm.com/docs/vpc?topic=vpc-using-vpn) in the IBM Cloud docs.

---

## Usage
```terraform
module vpc {
  # Replace "master" with a GIT release version to lock into a specific release
  source                      = "git::https://github.com/terraform-ibm-modules/terraform-ibm-landing-zone-vpc.git?ref=master"
  resource_group_id           = var.resource_group_id
  region                      = var.region
  prefix                      = var.prefix
  tags                        = var.tags
  vpc_name                    = var.vpc_name
  classic_access              = var.classic_access
  network_acls                = var.network_acls
  use_public_gateways         = var.use_public_gateways
  subnets                     = var.subnets
  vpn_gateways                = var.vpn_gateways
}
```

---

## Required IAM access policies
You need the following permissions to run this module.

- IAM services
    - **VPC Infrastructure** services
        - `Editor` platform access
    - **No service access**
        - **Resource Group** \<your resource group>
        - `Viewer` resource group access

---

<!-- BEGIN EXAMPLES HOOK -->
## Examples

- [ Default Example](examples/default)
<!-- END EXAMPLES HOOK -->
---

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0.0 |
| <a name="requirement_ibm"></a> [ibm](#requirement\_ibm) | >= 1.45.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_dynamic_values"></a> [dynamic\_values](#module\_dynamic\_values) | ./dynamic_values | n/a |
| <a name="module_unit_tests"></a> [unit\_tests](#module\_unit\_tests) | ./dynamic_values | n/a |

## Resources

| Name | Type |
|------|------|
| [ibm_is_network_acl.network_acl](https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs/resources/is_network_acl) | resource |
| [ibm_is_public_gateway.gateway](https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs/resources/is_public_gateway) | resource |
| [ibm_is_security_group_rule.default_vpc_rule](https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs/resources/is_security_group_rule) | resource |
| [ibm_is_subnet.subnet](https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs/resources/is_subnet) | resource |
| [ibm_is_vpc.vpc](https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs/resources/is_vpc) | resource |
| [ibm_is_vpc_address_prefix.address_prefixes](https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs/resources/is_vpc_address_prefix) | resource |
| [ibm_is_vpc_address_prefix.subnet_prefix](https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs/resources/is_vpc_address_prefix) | resource |
| [ibm_is_vpc_route.route](https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs/resources/is_vpc_route) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_address_prefixes"></a> [address\_prefixes](#input\_address\_prefixes) | OPTIONAL - IP range that will be defined for the VPC for a certain location. Use only with manual address prefixes | <pre>object({<br>    zone-1 = optional(list(string))<br>    zone-2 = optional(list(string))<br>    zone-3 = optional(list(string))<br>  })</pre> | <pre>{<br>  "zone-1": null,<br>  "zone-2": null,<br>  "zone-3": null<br>}</pre> | no |
| <a name="input_classic_access"></a> [classic\_access](#input\_classic\_access) | OPTIONAL - Classic Access to the VPC | `bool` | `false` | no |
| <a name="input_default_network_acl_name"></a> [default\_network\_acl\_name](#input\_default\_network\_acl\_name) | OPTIONAL - Name of the Default ACL. If null, a name will be automatically generated | `string` | `null` | no |
| <a name="input_default_routing_table_name"></a> [default\_routing\_table\_name](#input\_default\_routing\_table\_name) | OPTIONAL - Name of the Default Routing Table. If null, a name will be automatically generated | `string` | `null` | no |
| <a name="input_default_security_group_name"></a> [default\_security\_group\_name](#input\_default\_security\_group\_name) | OPTIONAL - Name of the Default Security Group. If null, a name will be automatically generated | `string` | `null` | no |
| <a name="input_name"></a> [name](#input\_name) | Name for VPC | `string` | n/a | yes |
| <a name="input_network_acls"></a> [network\_acls](#input\_network\_acls) | List of ACLs to create. Rules can be automatically created to allow inbound and outbound traffic from a VPC tier by adding the name of that tier to the `network_connections` list. Rules automatically generated by these network connections will be added at the beginning of a list, and will be web-tierlied to traffic first. At least one rule must be provided for each ACL. | <pre>list(<br>    object({<br>      name                = string<br>      network_connections = optional(list(string))<br>      add_cluster_rules   = optional(bool)<br>      rules = list(<br>        object({<br>          name        = string<br>          action      = string<br>          destination = string<br>          direction   = string<br>          source      = string<br>          tcp = optional(<br>            object({<br>              port_max        = optional(number)<br>              port_min        = optional(number)<br>              source_port_max = optional(number)<br>              source_port_min = optional(number)<br>            })<br>          )<br>          udp = optional(<br>            object({<br>              port_max        = optional(number)<br>              port_min        = optional(number)<br>              source_port_max = optional(number)<br>              source_port_min = optional(number)<br>            })<br>          )<br>          icmp = optional(<br>            object({<br>              type = optional(number)<br>              code = optional(number)<br>            })<br>          )<br>        })<br>      )<br>    })<br>  )</pre> | <pre>[<br>  {<br>    "add_cluster_rules": true,<br>    "name": "vpc-acl",<br>    "rules": [<br>      {<br>        "action": "allow",<br>        "destination": "0.0.0.0/0",<br>        "direction": "inbound",<br>        "name": "allow-all-inbound",<br>        "source": "0.0.0.0/0"<br>      },<br>      {<br>        "action": "allow",<br>        "destination": "0.0.0.0/0",<br>        "direction": "outbound",<br>        "name": "allow-all-outbound",<br>        "source": "0.0.0.0/0"<br>      }<br>    ]<br>  }<br>]</pre> | no |
| <a name="input_network_cidr"></a> [network\_cidr](#input\_network\_cidr) | Network CIDR for the VPC. This is used to manage network ACL rules for cluster provisioning. | `string` | `"10.0.0.0/8"` | no |
| <a name="input_prefix"></a> [prefix](#input\_prefix) | The prefix that you would like to append to your resources | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | The region to which to deploy the VPC | `string` | n/a | yes |
| <a name="input_resource_group_id"></a> [resource\_group\_id](#input\_resource\_group\_id) | The resource group ID where the VPC to be created | `string` | n/a | yes |
| <a name="input_routes"></a> [routes](#input\_routes) | OPTIONAL - Allows you to specify the next hop for packets based on their destination address | <pre>list(<br>    object({<br>      name        = string<br>      zone        = number<br>      destination = string<br>      next_hop    = string<br>    })<br>  )</pre> | `[]` | no |
| <a name="input_security_group_rules"></a> [security\_group\_rules](#input\_security\_group\_rules) | A list of security group rules to be added to the default vpc security group | <pre>list(<br>    object({<br>      name      = string<br>      direction = string<br>      remote    = string<br>      tcp = optional(<br>        object({<br>          port_max = optional(number)<br>          port_min = optional(number)<br>        })<br>      )<br>      udp = optional(<br>        object({<br>          port_max = optional(number)<br>          port_min = optional(number)<br>        })<br>      )<br>      icmp = optional(<br>        object({<br>          type = optional(number)<br>          code = optional(number)<br>        })<br>      )<br>    })<br>  )</pre> | <pre>[<br>  {<br>    "direction": "inbound",<br>    "name": "default-sgr",<br>    "remote": "10.0.0.0/8"<br>  }<br>]</pre> | no |
| <a name="input_subnets"></a> [subnets](#input\_subnets) | List of subnets for the vpc. For each item in each array, a subnet will be created. Items can be either CIDR blocks or total ipv4 addressess. Public gateways will be enabled only in zones where a gateway has been created | <pre>object({<br>    zone-1 = list(object({<br>      name           = string<br>      cidr           = string<br>      public_gateway = optional(bool)<br>      acl_name       = string<br>    }))<br>    zone-2 = list(object({<br>      name           = string<br>      cidr           = string<br>      public_gateway = optional(bool)<br>      acl_name       = string<br>    }))<br>    zone-3 = list(object({<br>      name           = string<br>      cidr           = string<br>      public_gateway = optional(bool)<br>      acl_name       = string<br>    }))<br>  })</pre> | <pre>{<br>  "zone-1": [<br>    {<br>      "acl_name": "vpc-acl",<br>      "cidr": "10.10.10.0/24",<br>      "name": "subnet-a",<br>      "public_gateway": true<br>    }<br>  ],<br>  "zone-2": [<br>    {<br>      "acl_name": "vpc-acl",<br>      "cidr": "10.20.10.0/24",<br>      "name": "subnet-b",<br>      "public_gateway": true<br>    }<br>  ],<br>  "zone-3": [<br>    {<br>      "acl_name": "vpc-acl",<br>      "cidr": "10.30.10.0/24",<br>      "name": "subnet-c",<br>      "public_gateway": false<br>    }<br>  ]<br>}</pre> | no |
| <a name="input_tags"></a> [tags](#input\_tags) | List of Tags for the resource created | `list(string)` | `null` | no |
| <a name="input_use_manual_address_prefixes"></a> [use\_manual\_address\_prefixes](#input\_use\_manual\_address\_prefixes) | OPTIONAL - Use manual address prefixes for VPC | `bool` | `false` | no |
| <a name="input_use_public_gateways"></a> [use\_public\_gateways](#input\_use\_public\_gateways) | Create a public gateway in any of the three zones with `true`. | <pre>object({<br>    zone-1 = optional(bool)<br>    zone-2 = optional(bool)<br>    zone-3 = optional(bool)<br>  })</pre> | <pre>{<br>  "zone-1": true,<br>  "zone-2": false,<br>  "zone-3": false<br>}</pre> | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_network_acls"></a> [network\_acls](#output\_network\_acls) | List of shortnames and IDs of network ACLs |
| <a name="output_public_gateways"></a> [public\_gateways](#output\_public\_gateways) | Map of public gateways by zone |
| <a name="output_subnet_detail_list"></a> [subnet\_detail\_list](#output\_subnet\_detail\_list) | A list of subnets containing names, CIDR blocks, and zones. |
| <a name="output_subnet_ids"></a> [subnet\_ids](#output\_subnet\_ids) | The IDs of the subnets |
| <a name="output_subnet_zone_list"></a> [subnet\_zone\_list](#output\_subnet\_zone\_list) | A list containing subnet IDs and subnet zones |
| <a name="output_vpc_crn"></a> [vpc\_crn](#output\_vpc\_crn) | CRN of VPC created |
| <a name="output_vpc_id"></a> [vpc\_id](#output\_vpc\_id) | ID of VPC created |
| <a name="output_vpc_name"></a> [vpc\_name](#output\_vpc\_name) | Name of VPC created |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

## Contributing

You can report issues and request features for this module in the [terraform-ibm-issue-tracker](https://github.com/terraform-ibm-modules/terraform-ibm-issue-tracker/issues) repo. See [Report an issue or request a feature](https://github.com/terraform-ibm-modules/.github/blob/main/.github/SUPPORT.md).

To set up your local development environment, see [Local development setup](https://terraform-ibm-modules.github.io/documentation/#/local-dev-setup) in the project documentation.
