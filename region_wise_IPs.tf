locals {
  us_south_ips = [
    "166.9.12.140/32",
    "166.9.12.141/32",
    "166.9.12.143/32",
    "166.9.12.142/32",
    "166.9.12.144/32",
    "166.9.12.151/32",
    "166.9.12.153/32",
    "166.9.12.192/32",
    "166.9.12.193/32",
    "166.9.12.194/32",
    "166.9.12.196/32",
    "166.9.12.233/32",
    "166.9.12.253/32",
    "166.9.12.26/32",
    "166.9.12.99/32",
    "166.9.13.31/32",
    "166.9.13.92/32",
    "166.9.13.93/32",
    "166.9.13.94/32",
    "166.9.14.121/32",
    "166.9.13.95/32",
    "166.9.14.122/32",
    "166.9.14.124/32",
    "166.9.14.125/32",
    "166.9.14.201/32",
    "166.9.14.202/32",
    "166.9.14.203/32",
    "166.9.14.204/32",
    "166.9.14.205/32",
    "166.9.14.206/32",
    "166.9.14.94/32",
    "166.9.14.95/32",
    "166.9.15.130/32",
  ]

  us_east_ips = [
    "166.9.20.11",
    "166.9.20.116",
    "166.9.20.117",
    "166.9.20.118",
    "166.9.20.12",
    "166.9.20.13",
    "166.9.20.187",
    "166.9.20.188",
    "166.9.20.37",
    "166.9.20.38",
    "166.9.20.42",
    "166.9.20.63",
    "166.9.20.79",
    "166.9.20.80",
    "166.9.22.10",
    "166.9.22.109",
    "166.9.22.110",
    "166.9.22.215",
    "166.9.22.216",
    "166.9.22.25",
    "166.9.22.26",
    "166.9.22.42",
    "166.9.22.43",
    "166.9.22.51",
    "166.9.22.52",
    "166.9.22.54",
    "166.9.22.55",
    "166.9.22.8",
    "166.9.22.9",
    "166.9.24.18",
    "166.9.24.19",
    "166.9.24.198",
    "166.9.24.199",
    "166.9.24.22",
    "166.9.24.35",
    "166.9.24.36",
    "166.9.24.4",
    "166.9.24.44",
    "166.9.24.45",
    "166.9.24.46",
    "166.9.24.47",
    "166.9.24.5",
    "166.9.24.90",
    "166.9.24.91",
    "166.9.68.134",
    "166.9.68.135",
    "166.9.68.34",
    "166.9.68.47",
    "166.9.232.15",
    "166.9.251.118",
    "166.9.231.217",
  ]

  us_south_inbound_rules = [
    for ip in local.us_south_ips : {
      name        = "ibmflow-${index(local.us_south_ips, ip)}-inbound-us-south"
      action      = "allow"
      source      = ip
      destination = var.network_cidr != null ? var.network_cidr : "0.0.0.0/0"
      direction   = "inbound"
      tcp         = null
      udp         = null
      icmp        = null
    }
  ]

  us_south_outbound_rules = [
    for ip in local.us_south_ips : {
      name        = "ibmflow-${index(local.us_south_ips, ip)}-outbound-us-south"
      action      = "allow"
      source      = var.network_cidr != null ? var.network_cidr : "0.0.0.0/0"
      destination = ip
      direction   = "outbound"
      tcp         = null
      udp         = null
      icmp        = null
    }
  ]

  us_east_inbound_rules = [
    for ip in local.us_east_ips : {
      name        = "ibmflow-${index(local.us_east_ips, ip)}-inbound-us-east"
      action      = "allow"
      source      = ip
      destination = var.network_cidr != null ? var.network_cidr : "0.0.0.0/0"
      direction   = "inbound"
      tcp         = null
      udp         = null
      icmp        = null
    }
  ]

  us_east_outbound_rules = [
    for ip in local.us_east_ips : {
      name        = "ibmflow-${index(local.us_east_ips, ip)}-outbound-us-east"
      action      = "allow"
      source      = var.network_cidr != null ? var.network_cidr : "0.0.0.0/0"
      destination = ip
      direction   = "outbound"
      tcp         = null
      udp         = null
      icmp        = null
    }
  ]
}
