# Specific Zone Only Example

<!-- BEGIN SCHEMATICS DEPLOY HOOK -->
<a href="https://cloud.ibm.com/schematics/workspaces/create?workspace_name=landing-zone-vpc-specific-zone-only-example&repository=https://github.com/terraform-ibm-modules/terraform-ibm-landing-zone-vpc/tree/main/examples/specific-zone-only"><img src="https://img.shields.io/badge/Deploy%20with IBM%20Cloud%20Schematics-0f62fe?logo=ibm&logoColor=white&labelColor=0f62fe" alt="Deploy with IBM Cloud Schematics" style="height: 16px; vertical-align: text-bottom;"></a>
<!-- END SCHEMATICS DEPLOY HOOK -->


A simple example to provision a Secure Landing Zone (SLZ) Virtual Private Cloud (VPC) in a specific zone other than Zone 1. Also, shows how to use public gateways with a specific zone. In this example Zone 2 is used. A network ACL is specifically defined to allow all internet traffic.

The following resources are provisioned by this example:

* A new resource group, if an existing one is not passed in.
* An IBM Virtual Private Cloud (VPC) with a publicly exposed subnet.

<!-- BEGIN SCHEMATICS DEPLOY TIP HOOK -->
:information_source: Ctrl/Cmd+Click or right-click on the Schematics deploy button to open in a new tab
<!-- END SCHEMATICS DEPLOY TIP HOOK -->
