##############################################################################
# Outputs
##############################################################################

output "vpc_id" {
  value       = var.create_vpc ? resource.ibm_is_vpc.example_vpc[0].id : null
  description = "VPC id"
}

output "subnet_id" {
  description = "Subnet ID"
  value       = var.create_vpc ? [resource.ibm_is_subnet.testacc_subnet[0].id] : []
}

output "postgresql_db_crn" {
  description = "Postgresql DB CRN"
  value       = var.create_db ? module.postgresql_db[0].crn : null
}
