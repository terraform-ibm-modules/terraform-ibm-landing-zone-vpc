terraform {
  required_version = ">= 1.3.0"
  required_providers {
    # Use "greater than or equal to" range in modules
    ibm = {
      source  = "IBM-Cloud/ibm"
      version = ">= 1.45.0"
    }
  }
}
