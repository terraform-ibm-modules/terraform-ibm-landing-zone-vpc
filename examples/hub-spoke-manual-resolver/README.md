# Hub and Spoke VPC with manual DNS resolver Example

<!-- BEGIN SCHEMATICS DEPLOY HOOK -->
<a href="https://cloud.ibm.com/schematics/workspaces/create?workspace_name=landing-zone-vpc-hub-spoke-manual-resolver-example&repository=https://github.com/terraform-ibm-modules/terraform-ibm-landing-zone-vpc/tree/main/examples/hub-spoke-manual-resolver"><img src="https://img.shields.io/badge/Deploy%20with IBM%20Cloud%20Schematics-0f62fe?logo=ibm&logoColor=white&labelColor=0f62fe" alt="Deploy with IBM Cloud Schematics" style="height: 16px; vertical-align: text-bottom;"></a>
<!-- END SCHEMATICS DEPLOY HOOK -->


This example demonstrates how to deploy hub and spoke VPCs, inclusive of enabling DNS-sharing using a manual DNS resolver in the spoke VPC (as opposed to a delegated resolver).

Caveat: Using a manual resolver, as opposed to a delegated resolver requires to ensure that the custom resolver IPs in the hub VPC do not change outside the terraform lifecycle (which should be the case if you follow a proper IaC approach).

Refer to the documentation [here](../hub-spoke-delegated-resolver/) if you are new to hub-spoke dns-sharing VPC topology.

<!-- BEGIN SCHEMATICS DEPLOY TIP HOOK -->
:information_source: Ctrl/Cmd+Click or right-click on the Schematics deploy button to open in a new tab
<!-- END SCHEMATICS DEPLOY TIP HOOK -->
