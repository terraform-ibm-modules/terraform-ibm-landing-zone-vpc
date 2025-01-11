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

###############

output "dns_zone_state" {
  description = "The state of the DNS zone."
  value       = module.slz_vpc.dns_zone_state
}

output "dns_zone" {
  description = "The ID of the DNS zone. The ID is composed of <instance_id>/<zone_id>"
  value       = module.slz_vpc.dns_zone
}

output "dns_zone_id" {
  description = "The ID of the zone that is associated with the DNS zone."
  value       = module.slz_vpc.dns_zone_id
}
output "dns_record_ids" {
  description = "List of all the domain resource records."
  value       = module.slz_vpc.dns_record_ids
}
