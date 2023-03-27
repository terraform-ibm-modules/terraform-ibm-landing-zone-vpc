##############################################################################
# Outputs
##############################################################################

output "cos_instance_crn" {
  value       = ibm_resource_instance.cos_instance[0].crn
  description = "COS instance crn"
}
