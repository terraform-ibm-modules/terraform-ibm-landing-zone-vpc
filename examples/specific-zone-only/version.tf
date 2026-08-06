terraform {
  required_version = ">= 1.9.0"
  required_providers {
    # Now using the stable 2.5.0 release which resolves the ACL rule destroy/recreate issue on inline updates.
    ibm = {
      source  = "IBM-Cloud/ibm"
      version = ">= 2.5.0"
    }
  }
}
