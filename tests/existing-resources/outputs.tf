##############################################################################
# Outputs
##############################################################################

output "vpc_id" {
  value       = resource.ibm_is_vpc.example_vpc.id
  description = "VPC id"
}

output "subnet_id" {
  description = "Subnet ID"
  value       = [resource.ibm_is_subnet.testacc_subnet.id]
}
