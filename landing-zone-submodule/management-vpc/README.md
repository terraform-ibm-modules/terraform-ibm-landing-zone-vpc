# Management VPC

You can use this submodule as a starting point to add capabilities incrementally.

Using this submodule, you can deploy a bare management VPC.
1. A single VPC:
   - Named `management` in this example
   - Includes three subnets across the three availability zone to host VSIs
   - Default, open network ACLs

This submodule also creates the following.
- A COS bucket which will be used for enabling flow logs.

:exclamation: **Important:** This example shows an example of basic topology. The topology is not highly available or validated for the IBM Cloud Framework for Financial Services.

Example usage:
```
export TF_VAR_ibmcloud_api_key=<your api key> # pragma: allowlist secret
terraform apply -var=region=eu-gb -var=prefix=my_slz
```