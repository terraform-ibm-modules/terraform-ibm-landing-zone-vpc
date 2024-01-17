# Hub and Spoke VPC Example

This example demonstrates how to deploy hub and spoke VPCs, inclusive of enabling DNS-sharing. See https://cloud.ibm.com/docs/vpc?topic=vpc-hub-spoke-model for details.

- The two VPCs are connected through a transit gateway.
- The hub VPC is configured with a custom resolver.
- The spoke VPC is configured with a delegated DNS resolver. DNS requests are resolved by the hub VPC.
- A DNS resolution binding relationship is configured to enable the hub VPC to DNS resolve VPE in the spoke VPC.


:exclamation: **Important**: Due to a limitation in the IBM Cloud terraform provider (1.59), there is a need to perform two applies as follows to end up with the desired topology:
1. The first terraform apply lays down all of the topology but does not configure the DNS resolver to delegated in the spoke
2. The second terraform apply should have the update_delegated_resolver variable set to true to configure the DNS resolver to be delegated ```terraform apply -var=update_delegated_resolver=true```

To successfully destroy, set the resolver to "system" in the spoke VPC through the UI before issuing the terraform destroy - see https://cloud.ibm.com/docs/vpc?topic=vpc-hub-spoke-configure-dns-resolver&interface=ui

You may also be interested in the [Hub and Spoke VPC with Manual DNS Resolver Example](../hub-spoke-manual-resolver/) which does not exhibit those issues.
