# Landing Zone example

<!-- BEGIN SCHEMATICS DEPLOY HOOK -->
<a href="https://cloud.ibm.com/schematics/workspaces/create?workspace_name=landing-zone-vpc-landing_zone-example&repository=https://github.com/terraform-ibm-modules/terraform-ibm-landing-zone-vpc/tree/main/examples/landing_zone"><img src="https://img.shields.io/badge/Deploy%20with IBM%20Cloud%20Schematics-0f62fe?logo=ibm&logoColor=white&labelColor=0f62fe" alt="Deploy with IBM Cloud Schematics" style="height: 16px; vertical-align: text-bottom;"></a>
<!-- END SCHEMATICS DEPLOY HOOK -->


This example demonstrates how to use the management and workload VPC [modules](https://github.com/terraform-ibm-modules/terraform-ibm-landing-zone-vpc/tree/main/modules) to create a network VPC topology that is aligned with the network segregation key principles of the IBM Cloud [Framework for Financial Services](https://cloud.ibm.com/docs/framework-financial-services?topic=framework-financial-services-vpc-architecture-connectivity-overview).

The example shows how to use the base modules to create the following topology:
- A management VPC
- A workload VPC
- A transit gateway that connects the two VPCs

:exclamation: **Important:** The topology created in this example does not meet all compliance controls for the IBM Cloud Framework for Financial Services. Use the [terraform-ibm-landing-zone](https://github.com/terraform-ibm-modules/terraform-ibm-landing-zone) module to create a fully compliant stack.

<!-- BEGIN SCHEMATICS DEPLOY TIP HOOK -->
:information_source: Ctrl/Cmd+Click or right-click on the Schematics deploy button to open in a new tab
<!-- END SCHEMATICS DEPLOY TIP HOOK -->
