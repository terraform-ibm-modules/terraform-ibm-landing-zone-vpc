##############################################################################
# Outputs
##############################################################################

output "vpc_names" {
  description = "VPC name"
  value       = module.workload_vpc.vpc_name
}