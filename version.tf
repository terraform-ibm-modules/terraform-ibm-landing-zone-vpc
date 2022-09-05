terraform {
  required_version = ">= 1.0.0"
  experiments      = [module_variable_optional_attrs]
  required_providers {
    # Use "greater than or equal to" range in modules
    ibm = {
      source  = "IBM-Cloud/ibm"
      version = ">= 1.45.0"
    }
  }
}
