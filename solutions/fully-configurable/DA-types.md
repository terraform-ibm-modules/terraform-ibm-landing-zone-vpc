# Configuring complex inputs for VPC

Several input variables in the **Cloud automation of VPC** [deployable architecture](https://cloud.ibm.com/catalog#deployable_architecture) use complex object types. You can specify these inputs when you configure your deployable architecture.

- [Subnets](#subnets) (`subnets`)
- [Network ACLs](#network-acls) (`network_acls`)
- [Security Group Rules](#security-group-rules)(`security_group_rules`)
- [Address Prefixes](#address-prefixes) (`address_prefixes`)
- [Routes](#routes) (`routes`)
- [VPN Gateways](#vpn-gateways) (`vpn_gateways`)
- [VPE Gateways Cloud Services](#cloud-services) (`vpe_gateway_cloud_services`)
- [VPE Gateways Cloud Service by CRN](#cloud-service-by-crn) (`vpe_gateway_cloud_service_by_crn`)
- [VPE Gateways Reserved IPs](#reserved-ips) (`vpe_gateway_reserved_ips`)

## Subnets <a name="subnets"></a>

This variable configuration allows you to specify the subnets for the VPC. For each item in each array, a subnet will be created. Items can be either CIDR blocks or total IPv4 addresses. Public gateways will be enabled only in zones where a gateway has been created.

- Variable name: `subnets`.
- Type: A object containing three zones. Each zone is a list of object.
- Default value: Subnet for `zone-1`.

### Options for subnets

For each zone, you can define the following:

  - `name` (required): The name of subnet
  - `cidr` (required): The cidr to define for the subnet
  - `public_gateway` (optional): (bool) Set to true if need to create public gateway for the zone
  - `acl_name` (required): The name of ACL created
  - `no_addr_prefix` (optional): (bool) Default is `false`, it does not add address prefix for subnet
  - `subnet_tags` (optional): (list) To specify tags for subnet specifically

### Example

```hcl
 {
    zone-1 = [
      {
        name           = "subnet-a"
        cidr           = "10.10.10.0/24"
        public_gateway = true
        acl_name       = "vpc-acl-a"
        no_addr_prefix = false
        subnet_tags    = ["public"]
      }
    ]
    zone-2 = [
      {
        name           = "subnet-b"
        cidr           = "10.10.20.0/24"
        public_gateway = true
        acl_name       = "vpc-acl-b"
        no_addr_prefix = false
      }
    ]
 }
```

## Network ACLs <a name="network-acls"></a>

This variable configuration allows you to specify the list of ACLs to create. Each ACL must have at least one rule defined.

- Variable name: `network_acls`.
- Type: A list of object.

### Options for Network ACLs

  - `name` (required): The name of network ACL.
  - `add_ibm_cloud_internal_rules` (optional): (bool) Set to true to include pre-defined rules defined [here](https://github.com/terraform-ibm-modules/terraform-ibm-landing-zone-vpc/blob/main/network_acls.tf#L50).
  - `add_vpc_connectivity_rules` (optional): (bool) Set to true to include pre-defined VPC connectivity rules defined [here](https://github.com/terraform-ibm-modules/terraform-ibm-landing-zone-vpc/blob/main/network_acls.tf#L102).
  - `prepend_ibm_rules` (optional): (bool) Set to true to prepend pre-defined rules defined [here](https://github.com/terraform-ibm-modules/terraform-ibm-landing-zone-vpc/blob/main/network_acls.tf#L132).
  - `rules` (required): (list of objects)
    - `name`: Name of the rule.
    - `action`: Allowed values are `allow` or `deny`.
    - `direction`: Allowed values are `inbound` or `outbound`.
    - `destination`: Destination address.
    - `source`: Source address.
    - `tcp` (optional):
      - `port_min`
      - `port_max`
      - `source_port_min`
      - `source_port_max`
    - `udp` (optional):
      - `port_min`
      - `port_max`
      - `source_port_min`
      - `source_port_max`
    - `icmp` (optional):
      - `type`
      - `code`

### Example

```hcl
 [
    {
      name                         = "vpc-acl"
      add_ibm_cloud_internal_rules = true
      add_vpc_connectivity_rules   = true
      prepend_ibm_rules            = true
      rules = [
        {
          name      = "allow-all-443-inbound"
          action    = "allow"
          direction = "inbound"
          tcp = {
            port_min        = 443
            port_max        = 443
            source_port_min = 443
            source_port_max = 443
          }
          destination = "0.0.0.0/0"
          source      = "0.0.0.0/0"
        }
      ]
    }
  ]
```

## Security Group Rules <a name="security-group-rules"></a>

This variable configuration allows you to specify the list of security group rules to be added to the default VPC security group. You can create a different type of protocol rules."

- Variable name: `security_group_rules`.
- Type: A list of object.
- Default value: An empty list (`[]`).

### Options for Security Group Rules

- `name` (required): The name of the security group rule.
- `direction` (required): The direction of the traffic. Allowed values are `inbound` or `outbound`.
- `remote` (optional): Security group ID or an IP address or a CIDR block.
- `tcp` (optional):
    - `port_min`
    - `port_max`
- `udp` (optional):
    - `port_min`
    - `port_max`
- `icmp` (optional):
    - `type`
    - `code`


### Example

```hcl
 [
    {
      name      = "security-group-rule-1"
      direction = "inbound"
      remote    = "127.0.0.1"
      tcp = {
        port_min = 8080
        port_max = 8080
      }
    }
  ]
```

## Address Prefixes <a name="address-prefixes"></a>

This variable allows you to specify the IP range for the VPC for a certain location.

- Variable name: `address_prefixes`.
- Type: A object including three zones. Each zone can have a list of address prefixes.
- Default value: `null` for each zone.

### Options for Address Prefixes

- `zone-1` (optional): (list) Address prefixes for zone-1.
- `zone-2` (optional): (list) Address prefixes for zone-2.
- `zone-3` (optional): (list) Address prefixes for zone-3.

### Example

```hcl
 {
    zone-1 = ["10.10.10.0/18"]
    zone-2 = null
    zone-3 = null
 }
```

## Routes <a name="routes"></a>

This variable allows you to add the custom routing tables and then add routes.

- Variable name: `routes`.
- Type: A list of object.
- Default value: An empty list `[]`.

### Options for Routes

- `name` (required): The name of the route.
- `route_direct_link_ingress` (optional): (bool) Required if the routing table will be used to route traffic that originates from Direct Link to the VPC.
- `route_transit_gateway_ingress` (optional): (bool) Required if the routing table will be used to route traffic that originates from the internet.
- `route_vpc_zone_ingress` (optional): (bool) Required if the routing table will be used to route traffic that originates from Transit Gateway to the VPC.
- `routes` (optional): (list)
  - `action`: The action to perform with a packet. Allowed values are `delegate`, `delegate_vpc`, `deliver`, `drop`.
  - `zone`: Number of the zone.
  - `destination`: The destination of the route.
  - `next_hop`: The next hop of the route. For action other than deliver, you must specify `0.0.0.0`.

### Example

```hcl
 {
  name = "route-1"
  route_direct_link_ingress = false
  route_transit_gateway_ingress = false
  route_vpc_zone_ingress = true
  routes = [
    {
      zone        = 1
      destination = "10.10.10.0/24"
      next_hop    = "10.10.0.4"
      action      = "deliver"
    }
  ]
 }
```

## VPN Gateways <a name="vpn-gateways"></a>

This variable allows you to specify the list of VPN Gateways to create.

- Variable name: `vpn_gateways`.
- Type: A list of object.
- Default value: An empty list `[]`.

### Options for VPN Gateways

- `name` (required): Name of the VPN gateway.
- `subnet_name` (required): Name of the subnet to attach a VPN gateway.
- `mode` (optional): Mode in VPN gateway. Allowed values are `route` and `policy`.
- `resource_group` (optional): The resource group where the VPN gateway to be created.
- `access_tags` (optional): (list) A list of tags to add to your VPN gateway.

### Example

```hcl
 {
  name = "vpn-gateway-1"
  subnet_name = "subnet-a"
  mode = "route"
}
```

## VPE Gateway Cloud Services <a name="cloud-services"></a>

This variable configuration allows you to specify the list of cloud services used to create endpoint gateways.

- Variable name: `vpe_gateway_cloud_services`.
- Type: A list of object.
- Default value: An empty list `[]`.

### Options for VPE Gateway Cloud Services

- `service_name` (required): The name of the Cloud service.
- `vpe_name` (optional): The name of the VPE gateway. If it is not specified, VPE name will be automatically generated in the format `<prefix>-<vpc_name>-<service_name>`.
- `allow_dns_resolution_binding` (optional): (bool) Set to `true` to allow this endpoint gateway to participate in DNS resolution bindings with a VPC.

### Example

```hcl
 {
  service_name = "cloud-object-storage"
  vpe_name = "vpe1"
 }
```

## VPE Gateway Cloud Service by CRN <a name="cloud-service-by-crn"></a>

This variable defines cloud service CRNs required to create endpoint gateways. This list is used to identify services that are not supported by service name in the `cloud_services` variable. For a list of supported services, see [VPE-enabled services](https://cloud.ibm.com/docs/vpc?topic=vpc-vpe-supported-services).

- Variable name: `vpe_gateway_cloud_service_by_crn`.
- Type: A list of object.
- Default value: An empty list `[]`.

### Options for VPE Gateway Cloud Services by CRN

- `crn` (required): The CRN of the Cloud service.
- `vpe_name` (optional): The name of the VPE gateway. If it is not specified, VPE name will be automatically generated in the format `<prefix>-<vpc_name>-<service_name>`.
- `service_name` (optional): The name of the service. Required to compute the name of VPE. If not specified, the service name will be obtained from the crn.
- `allow_dns_resolution_binding` (optional): (bool) Set to `true` to allow this endpoint gateway to participate in DNS resolution bindings with a VPC.

### Example

```hcl
 {
  crn = "crn:v1:bluemix:public:cloud-object-storage:global:::endpoint:s3.direct.mil01.cloud-object-storage.appdomain.cloud"
  vpe_name = "vpe2"
 }
```

## VPE Gateways Reserved IPs <a name="reserved-ips"></a>

This variable defines a map of existing reserved IP names and values to attach with the endpoint gateways. This value is used when a user uses the existing reserved ips instead of creating new."

- Variable name: `vpe_gateway_reserved_ips`.
- Type: A object.
- Default value: An empty object `{}`.

### Options for VPE Gateway Cloud Services by CRN

- `name` (optional): The name of the reserved IP with its value.

### Example

```hcl
 {
  name = "vpe-reserved-ip"
 }
```
