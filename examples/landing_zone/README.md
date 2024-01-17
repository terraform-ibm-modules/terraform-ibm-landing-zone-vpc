# Landing Zone Example

This example demonstrates how to use the management and workload VPC [modules](../../landing-zone-submodule/) to create a network VPC topology that aligns with the network segregation key principles of the IBM Cloud [Framework for Financial Services](https://cloud.ibm.com/docs/framework-financial-services?topic=framework-financial-services-vpc-architecture-connectivity-overview).

The example shows how to use the base modules to create the following topology:
- A management VPC
- A workload VPC
- A transit gateway connecting the two VPCs

:exclamation: **Important:** The topology created in this example does not meet all compliance controls for the IBM Cloud Framework for Financial Services. Use the [terraform-ibm-landing-zone](https://github.com/terraform-ibm-modules/terraform-ibm-landing-zone) module to create a fully compliant stack.
