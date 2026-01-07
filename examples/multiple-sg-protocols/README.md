# Multiple Security Group Protocols Example

This example demonstrates how to configure multiple security group rules with different protocols for the same source CIDR with the module.

**Note:** IBM Cloud VPC security group rules do not support specifying multiple protocols in a single rule. When you need to allow traffic from the same source using different protocols (e.g., TCP, UDP, ICMP), you must create separate security group rules for each protocol. This example shows the correct approach to handle this requirement.

The following resources are provisioned by this example:

* A new resource group, if an existing one is not passed in.
* An IBM Virtual Private Cloud (VPC) with:
  * Publicly exposed subnet.
  * Custom security group rules demonstrating multiple inbound rules using different protocols (TCP, UDP, ICMP) and ports for the same source (remote) CIDR block (0.0.0.0/0).
    * SSH (TCP port 22)
    * HTTP (TCP port 80)
    * HTTPS (TCP port 443)
    * DNS (UDP port 53)
    * ICMP Echo (ping)
  * [Optional] Commented code to demonstrate a Security Group rule that allows all inbound traffic from anywhere to anywhere on _all ports_ for ipv4. If you uncomment that code, it would make the rest of the Security Group rules redundant.
