# Hub and Spoke VPC Example

<!-- BEGIN SCHEMATICS DEPLOY HOOK -->
<a href="https://cloud.ibm.com/schematics/workspaces/create?workspace_name=landing-zone-vpc-hub-spoke-delegated-resolver-example&repository=https://github.com/terraform-ibm-modules/terraform-ibm-landing-zone-vpc/tree/main/examples/hub-spoke-delegated-resolver"><img src="https://img.shields.io/badge/Deploy%20with IBM%20Cloud%20Schematics-0f62fe?logo=ibm&logoColor=white&labelColor=0f62fe" alt="Deploy with IBM Cloud Schematics" style="height: 16px; vertical-align: text-bottom;"></a>
<!-- END SCHEMATICS DEPLOY HOOK -->


This example demonstrates how to deploy hub and spoke VPCs, inclusive of enabling DNS-sharing. See [About DNS sharing for VPE gateways](https://cloud.ibm.com/docs/vpc?topic=vpc-vpe-dns-sharing) and [hub and spoke communication](https://cloud.ibm.com/docs/solution-tutorials?topic=solution-tutorials-vpc-transit1) for details.
- The 2 VPCs are connected through a transit gateway.
- The hub VPC is configured with a custom resolver.
- The spoke VPC is configured with a delegated DNS resolver. DNS requests are resolved by the hub VPC.
- An authorization policy for the DNS Binding Connector role is created to allow the spoke VPC to use the DNS resolution of the hub VPC, this also allows the hub and spoke VPCs to be in separate accounts.
- A DNS resolution binding relationship is configured to enable the hub VPC to DNS resolve VPE in the spoke VPC.


:exclamation: **Important**: Due to a limitation in the IBM Cloud terraform provider (1.59), there is a need to perform 2 applies as follows to end up with the desired topology:
1. The first terraform apply lay down all of the topology, but does not configure the DNS resolver to delegated in the spoke
2. The second terraform apply should have the update_delegated_resolver variable to true to configure the DNS resolver to be delegated ```terraform apply -var=update_delegated_resolver=true```

You may also be interested in the [Hub and Spoke VPC with manual DNS resolver Example](../hub-spoke-manual-resolver/) which does not exhibit those issues.

<!-- BEGIN SCHEMATICS DEPLOY TIP HOOK -->
:information_source: Ctrl/Cmd+Click or right-click on the Schematics deploy button to open in a new tab
<!-- END SCHEMATICS DEPLOY TIP HOOK -->
