# Basic Example with multiple Security Group rules

A simple example to provision a Secure Landing Zone (SLZ) Virtual Private Cloud (VPC).

The following resources are provisioned by this example:

* A new resource group, if an existing one is not passed in.
* An IBM Virtual Private Cloud (VPC) with:
  * Publicly exposed subnet.
  * Custom security group rules demonstrating multiple inbound rules using different protocols and ports for the same source(remote) CIDR.
  * [Optional] Commented code to demonstrate Security Group rule allow all inbound traffic from anywhere to anywhere on _all ports_ for ipv4. If you uncomment that code, it would make rest of the Security Group rules redundant.
