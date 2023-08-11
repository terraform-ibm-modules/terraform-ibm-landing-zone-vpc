terraform {
  required_version = ">= 1.3.0"
  required_providers {
    # Use "greater than or equal to" range in modules
    ibm = {
      source  = "IBM-Cloud/ibm"
      version = ">= 1.52.0"
    }
    time = {
      source  = "hashicorp/time"
      version = ">= 0.9.1"
    }
    null = {
      source  = "hashicorp/null"
      version = ">= 3.2.1"
    }
  }
}
