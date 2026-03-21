# Basic Example

<!-- BEGIN SCHEMATICS DEPLOY HOOK -->
<p>
  <a href="https://cloud.ibm.com/schematics/workspaces/create?workspace_name=landing-zone-vpc-basic-example&repository=https://github.com/terraform-ibm-modules/terraform-ibm-landing-zone-vpc/tree/main/examples/basic">
    <img src="https://img.shields.io/badge/Deploy%20with%20IBM%20Cloud%20Schematics-0f62fe?style=flat&logo=ibm&logoColor=white&labelColor=0f62fe" alt="Deploy with IBM Cloud Schematics">
  </a><br>
  ℹ️ Ctrl/Cmd+Click or right-click on the Schematics deploy button to open in a new tab.
</p>
<!-- END SCHEMATICS DEPLOY HOOK -->

A simple example to provision a Secure Landing Zone (SLZ) Virtual Private Cloud (VPC).

The following resources are provisioned by this example:

* A new resource group, if an existing one is not passed in.
* An IBM Virtual Private Cloud (VPC) with:
  * Publicly exposed subnet.
  * Custom security group rules.
