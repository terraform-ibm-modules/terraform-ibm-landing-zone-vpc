# Hub and Spoke VPC Example

This example demonstrates how to deploy hub and spoke VPCs, inclusive of enabling DNS-sharing. See [About DNS sharing for VPE gateways](https://cloud.ibm.com/docs/vpc?topic=vpc-vpe-dns-sharing) and [hub and spoke communication](https://cloud.ibm.com/docs/solution-tutorials?topic=solution-tutorials-vpc-transit1) for details.
- The 2 VPCs are connected through a transit gateway.
- The hub VPC is configured with a custom resolver.
- The spoke VPC is configured with a delegated DNS resolver. DNS requests are resolved by the hub VPC.
- An authorization policy for the DNS Binding Connector role is created to allow the spoke VPC to use the DNS resolution of the hub VPC, this also allows the hub and spoke VPCs to be in separate accounts.
- A DNS resolution binding relationship is configured to enable the hub VPC to DNS resolve VPE in the spoke VPC.


:exclamation: **Important**: Due to a limitation in the IBM Cloud terraform provider (1.59), there is a need to perform 2 applies as follows to end up with the desired topology:
1. The first terraform apply lay down all of the topology, but does not configure the DNS resolver to delegated in the spoke
2. The second terraform apply should have the update_delegated_resolver variable to true to configure the DNS resolver to be delegated ```terraform apply -var=update_delegated_resolver=true```

In order to perform a successful destroy, please set to the resolver to "system" in the spoke VPC through the UI before issuing the terraform destroy - see https://cloud.ibm.com/docs/solution-tutorials?topic=solution-tutorials-vpc-transit2

You may also be interested in the [Hub and Spoke VPC with manual DNS resolver Example](../hub-spoke-manual-resolver/) which does not exhibit those issues.
