# Hub and Spoke VPC with manual DNS resolver Example

This example demostrates how to deploy hub and spoke VPCs, inclusive of enabling DNS-sharing using a manual DNS resolver in the spoke VPC (as opposed to a delegated resolver).

Caveat: Using a manual resolver, as opposed to a delegated resolver requires to ensure that the custom resolver IPs in the hub VPC do not change outside the terraform lifecycle (which should be the case if you follow a proper IaC approach).

Refer to the documentation [here](../hub-spoke-delegated-resolver/) if you are new to hub-spoke dns-sharing VPC topology.
