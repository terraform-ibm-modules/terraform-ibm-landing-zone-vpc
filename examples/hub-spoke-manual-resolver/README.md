# Hub and Spoke VPC with Manual DNS Resolver Example

This example demonstrates how to deploy hub and spoke VPCs, inclusive of enabling DNS-sharing using a manual DNS resolver in the spoke VPC (as opposed to a delegated resolver).

Caveat: Using a manual resolver, as opposed to a delegated resolver, requires ensuring that the custom resolver IPs in the hub VPC do not change outside the Terraform lifecycle (which should be the case if you follow a proper IaC approach).

Refer to the documentation [here](../hub-spoke-delegated-resolver/) if you are new to hub-spoke DNS-sharing VPC topology.
