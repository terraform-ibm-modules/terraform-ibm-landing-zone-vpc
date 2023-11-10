# Hub and Spoke VPC Example

This example demonstrates how to deploy hub and spoke VPCs:

This example creates:
- Resource group, if one is not provided.
- A Hub VPC
- DNS Hub
- Custom resolver
- A Spoke VPC with "delegated" resolver.
- A transit gateway connection between Hub VPC and Spoke VPC

## Note:
This example runs in a 2-step terraform apply process.

**First terraform apply:** Run the example as is. This step sets up Hub VPC, Spoke VPC, Transit Gateway, DNS Hub and Custom resolver.

**Second terraform apply:** Before running the second apply, uncomment `update_delegated_resolver = true`.

**Destroy:** Make sure to manually change the resolver type from "delegated" to "system" for Spoke VPC before destroying everything else.
