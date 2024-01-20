# Landing Zone Management VPC (Standalone)

This specialized submodule calls the root [landing-zone-vpc module](../..) with a preset configuration that results in a management VPC with a topology that is identical to the management VPC created by the [terraform-ibm-landing-zone module](https://github.com/terraform-ibm-modules/terraform-ibm-landing-zone/tree/main).

You can use this submodule when you need more modularity to create your topology than the terraform-ibm-landing-zone module provides. This submodule provides one of the building blocks for this topology.

See the [Landing Zone example](../../examples/landing_zone/) for runnable code.

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
### Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.0, <1.6.0 |

### Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_management_vpc"></a> [management\_vpc](#module\_management\_vpc) | ../../ | n/a |

### Resources

No resources.

### Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_access_tags"></a> [access\_tags](#input\_access\_tags) | Optional list of access tags to add to the VPC resources that are created | `list(string)` | `[]` | no |
| <a name="input_address_prefixes"></a> [address\_prefixes](#input\_address\_prefixes) | Use `address_prefixes` only if `use_manual_address_prefixes` is true otherwise prefixes will not be created. Use only if you need to manage prefixes manually. | <pre>object({<br>    zone-1 = optional(list(string))<br>    zone-2 = optional(list(string))<br>    zone-3 = optional(list(string))<br>  })</pre> | `null` | no |
| <a name="input_classic_access"></a> [classic\_access](#input\_classic\_access) | Optionally allow VPC to access classic infrastructure network | `bool` | `null` | no |
| <a name="input_clean_default_sg_acl"></a> [clean\_default\_sg\_acl](#input\_clean\_default\_sg\_acl) | Remove all rules from the default VPC security group and VPC ACL (less permissive) | `bool` | `false` | no |
| <a name="input_create_authorization_policy_vpc_to_cos"></a> [create\_authorization\_policy\_vpc\_to\_cos](#input\_create\_authorization\_policy\_vpc\_to\_cos) | Set it to true if authorization policy is required for VPC to access COS | `bool` | `false` | no |
| <a name="input_default_network_acl_name"></a> [default\_network\_acl\_name](#input\_default\_network\_acl\_name) | Override default ACL name | `string` | `null` | no |
| <a name="input_default_routing_table_name"></a> [default\_routing\_table\_name](#input\_default\_routing\_table\_name) | Override default VPC routing table name | `string` | `null` | no |
| <a name="input_default_security_group_name"></a> [default\_security\_group\_name](#input\_default\_security\_group\_name) | Override default VPC security group name | `string` | `null` | no |
| <a name="input_default_security_group_rules"></a> [default\_security\_group\_rules](#input\_default\_security\_group\_rules) | Override default security group rules | <pre>list(<br>    object({<br>      name      = string<br>      direction = string<br>      remote    = string<br>      tcp = optional(<br>        object({<br>          port_max = optional(number)<br>          port_min = optional(number)<br>        })<br>      )<br>      udp = optional(<br>        object({<br>          port_max = optional(number)<br>          port_min = optional(number)<br>        })<br>      )<br>      icmp = optional(<br>        object({<br>          type = optional(number)<br>          code = optional(number)<br>        })<br>      )<br>    })<br>  )</pre> | `[]` | no |
| <a name="input_enable_vpc_flow_logs"></a> [enable\_vpc\_flow\_logs](#input\_enable\_vpc\_flow\_logs) | Enable VPC Flow Logs, it will create Flow logs collector if set to true | `bool` | `false` | no |
| <a name="input_existing_cos_bucket_name"></a> [existing\_cos\_bucket\_name](#input\_existing\_cos\_bucket\_name) | Name of the COS bucket to collect VPC flow logs | `string` | `null` | no |
| <a name="input_existing_cos_instance_guid"></a> [existing\_cos\_instance\_guid](#input\_existing\_cos\_instance\_guid) | GUID of the COS instance to create Flow log collector | `string` | `null` | no |
| <a name="input_network_acls"></a> [network\_acls](#input\_network\_acls) | List of network ACLs to create with VPC | <pre>list(<br>    object({<br>      name                         = string<br>      add_ibm_cloud_internal_rules = optional(bool)<br>      add_vpc_connectivity_rules   = optional(bool)<br>      prepend_ibm_rules            = optional(bool)<br>      rules = list(<br>        object({<br>          name        = string<br>          action      = string<br>          destination = string<br>          direction   = string<br>          source      = string<br>          tcp = optional(<br>            object({<br>              port_max        = optional(number)<br>              port_min        = optional(number)<br>              source_port_max = optional(number)<br>              source_port_min = optional(number)<br>            })<br>          )<br>          udp = optional(<br>            object({<br>              port_max        = optional(number)<br>              port_min        = optional(number)<br>              source_port_max = optional(number)<br>              source_port_min = optional(number)<br>            })<br>          )<br>          icmp = optional(<br>            object({<br>              type = optional(number)<br>              code = optional(number)<br>            })<br>          )<br>        })<br>      )<br>    })<br>  )</pre> | <pre>[<br>  {<br>    "add_ibm_cloud_internal_rules": true,<br>    "add_vpc_connectivity_rules": true,<br>    "name": "management-acl",<br>    "prepend_ibm_rules": true,<br>    "rules": []<br>  }<br>]</pre> | no |
| <a name="input_network_cidrs"></a> [network\_cidrs](#input\_network\_cidrs) | Network CIDR for the VPC. This is used to manage network ACL rules for cluster provisioning. | `list(string)` | <pre>[<br>  "10.0.0.0/8"<br>]</pre> | no |
| <a name="input_prefix"></a> [prefix](#input\_prefix) | The prefix that you would like to append to your resources | `string` | `"management"` | no |
| <a name="input_region"></a> [region](#input\_region) | The region to which to deploy the VPC | `string` | `"au-syd"` | no |
| <a name="input_resource_group_id"></a> [resource\_group\_id](#input\_resource\_group\_id) | The resource group ID where the VPC to be created | `string` | n/a | yes |
| <a name="input_subnets"></a> [subnets](#input\_subnets) | Object for subnets to be created in each zone, each zone can have any number of subnets | <pre>object({<br>    zone-1 = list(object({<br>      name           = string<br>      cidr           = string<br>      public_gateway = optional(bool)<br>      acl_name       = string<br>    }))<br>    zone-2 = list(object({<br>      name           = string<br>      cidr           = string<br>      public_gateway = optional(bool)<br>      acl_name       = string<br>    }))<br>    zone-3 = list(object({<br>      name           = string<br>      cidr           = string<br>      public_gateway = optional(bool)<br>      acl_name       = string<br>    }))<br>  })</pre> | <pre>{<br>  "zone-1": [<br>    {<br>      "acl_name": "management-acl",<br>      "cidr": "10.10.10.0/24",<br>      "name": "vsi-zone-1",<br>      "public_gateway": false<br>    },<br>    {<br>      "acl_name": "management-acl",<br>      "cidr": "10.10.20.0/24",<br>      "name": "vpe-zone-1",<br>      "public_gateway": false<br>    },<br>    {<br>      "acl_name": "management-acl",<br>      "cidr": "10.10.30.0/24",<br>      "name": "vpn-zone-1",<br>      "public_gateway": false<br>    }<br>  ],<br>  "zone-2": [<br>    {<br>      "acl_name": "management-acl",<br>      "cidr": "10.20.10.0/24",<br>      "name": "vsi-zone-2",<br>      "public_gateway": false<br>    },<br>    {<br>      "acl_name": "management-acl",<br>      "cidr": "10.20.20.0/24",<br>      "name": "vpe-zone-2",<br>      "public_gateway": false<br>    }<br>  ],<br>  "zone-3": [<br>    {<br>      "acl_name": "management-acl",<br>      "cidr": "10.30.10.0/24",<br>      "name": "vsi-zone-3",<br>      "public_gateway": false<br>    },<br>    {<br>      "acl_name": "management-acl",<br>      "cidr": "10.30.20.0/24",<br>      "name": "vpe-zone-3",<br>      "public_gateway": false<br>    }<br>  ]<br>}</pre> | no |
| <a name="input_tags"></a> [tags](#input\_tags) | List of tags to apply to resources created by this module. | `list(string)` | `[]` | no |
| <a name="input_use_public_gateways"></a> [use\_public\_gateways](#input\_use\_public\_gateways) | For each `zone` that is set to `true`, a public gateway will be created in that zone | <pre>object({<br>    zone-1 = optional(bool)<br>    zone-2 = optional(bool)<br>    zone-3 = optional(bool)<br>  })</pre> | <pre>{<br>  "zone-1": false,<br>  "zone-2": false,<br>  "zone-3": false<br>}</pre> | no |

### Outputs

| Name | Description |
|------|-------------|
| <a name="output_vpc_crn"></a> [vpc\_crn](#output\_vpc\_crn) | CRN of VPC created |
| <a name="output_vpc_id"></a> [vpc\_id](#output\_vpc\_id) | ID of VPC created |
| <a name="output_vpc_name"></a> [vpc\_name](#output\_vpc\_name) | VPC name |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
