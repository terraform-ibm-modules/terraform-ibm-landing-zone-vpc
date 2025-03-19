# Configuring complex inputs for VPC in IBM Cloud projects
Several optional input variables in the IBM Cloud [VPC deployable architecture](https://cloud.ibm.com/catalog#deployable_architecture) use complex object types. You can specify these inputs when you configure your deployable architecture.

- [Subnets](#options-with-subnets) (`subnets`)
- [Network Acls](#options-with-network-acls) (`network_acls`)
- [Address Prefixes](#options-with-address-prefixes) (`address_prefixes`)
- [Routes](#options-with-routes) (`routes`)
- [Vpn Gateways](#options-with-vpn-gateways) (`vpn_gateways`)
- [Cloud Services](#options-with-cloud-services) (`cloud_services`)
- [Cloud Service by crn](#options-with-cloud-service-by-crn) (`cloud_service_by_crn`)

## Options with subnets <a name="options-with-subnets"></a>

This variable configuration allows you to specify the subnets for the VPC. For each item in each array, a subnet will be created. Items can be either CIDR blocks or total IPv4 addresses. Public gateways will be enabled only in zones where a gateway has been created.

### Example for subnets

```hcl
subnets = {
    zone-1 = [
      {
        name           = "subnet-a"
        cidr           = "10.10.10.0/24"
        public_gateway = true
        acl_name       = "vpc-acl"
        no_addr_prefix = false
      }
    ]
}
```

## Options with network_acls <a name="options-with-network-acls"></a>

This variable configuration allows you to specify the list of ACLs to create. Each ACL must have at least one rule defined.

### Example for network-acls

```hcl
network_acls = {
    default = [
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
}
```

## Options with address_prefixes <a name="options-with-address-prefixes"></a>

This variable configuration allows you to specify the list of ACLs to create. Each ACL must have at least one rule defined.

### Example for address-prefixes

```hcl
address_prefixes = {
    default = {
    zone-1 = null
    zone-2 = null
    zone-3 = null
  }
}
```

## Options with routes <a name="options-with-routes"></a>

This variable configuration allows you to specify the next hop for packets based on their destination address.

### Example for routes

```hcl
routes = {
  name = "test-route"
      routes = [
        {
          zone        = 1
          destination = "10.2.14.1/32"
          next_hop    = "1.1.1.1"
        }
      ]
}
```

## Options with vpn_gateways <a name="options-with-vpn-gateways"></a>

This variable configuration allows you to specify the list of VPN Gateways to create.

### Example for vpn_gateways

```hcl
vpn_gateways = {

  
}
```

## Options with cloud_services <a name="options-with-cloud-services"></a>

This variable configuration allows you to specify the list of cloud services used to create endpoint gateways. If `vpe_name` is not specified in the list, VPE names will be generated in the format `<prefix>-<vpc_name>-<service_name>`.

### Example for cloud_services

```hcl
cloud_services = {
  
}
```

## Options with cloud_services <a name="options-with-cloud-service-by-crn"></a>

This variable defines cloud service CRNs for endpoint gateways, used when `cloud_services` lacks support. If `service_name` is absent, the CRN sets the name. Missing `vpe_name` results in names like `<prefix>-<vpc_name>-<service_name>`.

### Example for cloud_service-by-crn

```hcl
cloud_service_by_crn = {
  
}
```