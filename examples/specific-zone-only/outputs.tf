##############################################################################
# Outputs
##############################################################################

output "vpc_id" {
  value       = module.slz_vpc.vpc_id
  description = "VPC id"
}

output "vpc_crn" {
  value       = module.slz_vpc.vpc_crn
  description = "VPC crn"
}

output "network_acls" {
  value       = module.slz_vpc.network_acls
  description = "VPC network ACLs"
}

output "public_gateways" {
  value       = module.slz_vpc.public_gateways
  description = "VPC public gateways"
}

output "subnet_zone_list" {
  value       = module.slz_vpc.subnet_zone_list
  description = "VPC subnet zone list"
}

output "subnet_detail_map" {
  value       = module.slz_vpc.subnet_detail_map
  description = "VPC subnet detail map"
}
