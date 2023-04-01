# Landing Zone Example

This example creates two VPCs
- Workload VPC
- Management VPC

Created using default values, workload_vpc has flow_logs enabled and management_vpc doesn't have the flow logs enabled.

:exclamation: **Important:** The cos instance/bucket created in this example is not fscloud compliant. Refer this [link](https://github.com/terraform-ibm-modules/terraform-ibm-cos/tree/main/profiles/fscloud) to create a fscloud compliant instance/bucket.
