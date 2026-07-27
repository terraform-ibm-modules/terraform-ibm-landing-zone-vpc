terraform {
  required_version = ">= 1.9.0"
  required_providers {
    # Pinned to 2.5.0-beta0 which resolves the ACL rule destroy/recreate issue on inline updates.
    # Update to ">= 2.5.0" once the stable release is published.
    ibm = {
      source  = "IBM-Cloud/ibm"
      version = "= 2.5.0-beta0"
    }
  }
}
