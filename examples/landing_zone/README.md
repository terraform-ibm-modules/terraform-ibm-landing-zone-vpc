# Landing Zone Example

This example demonstrates how to use the management and workload vpc module to create a network VPC topology that is aligned with the [Financial Services Framework](https://cloud.ibm.com/docs/framework-financial-services?topic=framework-financial-services-vpc-architecture-connectivity-overview) network segregation key principles.

The purpose of this example is to show how to use base modules to create such topology:
- A management VPC
- A workload VPC
- A transit gateway connecting the two VPCs

:exclamation: **Important:** The topology created in this example does not meet all compliance controls for Financial Services. Use the [terraform-ibm-landing-zone](https://github.com/terraform-ibm-modules/terraform-ibm-landing-zone) module to create a fully compliant stack.
