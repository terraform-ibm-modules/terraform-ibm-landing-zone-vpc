locals {
  region_wise_ips = {
    au-syd = ["10.201.16.0/20", "10.202.16.0/20"]
    br-sao = [ "10.200.80.0/20", "10.202.240.0/20"]
    ca-tor = ["10.2.48.0/20", "10.202.176.0/20", "10.202.192.0/20"]
    eu-de = ["10.200.96.0/20", "10.2.64.0/20", "10.3.128.0/20", "10.3.80.0/20", "10.201.112.0/20", "10.201.128.0/20", "10.3.144.0/20", "10.2.144.0/20"]
    eu-gb = ["10.2.64.0/20", "10.1.208.0/20", "10.201.32.0/20", "10.201.48.0/20", "10.201.64.0/20"]
    jp-osa = ["10.202.112.0/20", "10.202.144.0/20", "10.202.160.0/20"]
    jp-tok = ["10.200.16.0/20", "10.2.160.0/20", "10.200.64.0/20", "10.2.32.0/20", "10.3.64.0/20", "10.201.176.0/20", "10.201.192.0/20"]
    us-east = ["10.3.112.0/20", "10.2.48.0/20", "10.200.160.0/20", "10.200.176.0/20"]
    us-south = ["10.200.112.0/20", "10.200.128.0/20", "10.1.160.0/20", "10.2.176.0/20", "10.200.0.0/20", "10.3.176.0/20"]
    common = ["10.0.64.0/19", "10.200.80.0/20", "10.3.160.0/20", "10.201.0.0/20", "10.201.80.0/20"]
  }

  /*
    skipped ip: au-syd: "10.3.96.0/20"
    skipped ip: br-sao: "10.200.0.0/20",
  */

  region_wise_inbound_rules = flatten([
      for region, ips in local.region_wise_ips: [
        for index, ip in ips: {
          name        = "ibmflow-${index}-inbound-${region}"
          action      = "allow"
          source      = ip
          destination = var.network_cidr != null ? var.network_cidr : "0.0.0.0/0"
          direction   = "inbound"
          tcp         = null
          udp         = null
          icmp        = null
        }
      ]
  ])

    region_wise_outbound_rules = flatten([
      for region, ips in local.region_wise_ips: [
        for index, ip in ips: {
          name        = "ibmflow-${index}-outbound-${region}"
          action      = "allow"
          source      = var.network_cidr != null ? var.network_cidr : "0.0.0.0/0"
          destination = ip
          direction   = "outbound"
          tcp         = null
          udp         = null
          icmp        = null
        }
      ]
  ])  
}
