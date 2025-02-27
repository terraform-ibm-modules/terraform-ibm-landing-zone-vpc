# IBM VPC deployable architecture

This deployable architecture supports provisioning the following resources:

- A new resource group if one is not passed in.
- A VPC.


![vpc-deployable-architecture](../../reference-architecture/vpc-quickstart-da.svg)

:exclamation: **Important:** This solution is not intended to be called by other modules because it contains a provider configuration and is not compatible with the `for_each`, `count`, and `depends_on` arguments. For more information, see [Providers Within Modules](https://developer.hashicorp.com/terraform/language/modules/develop/providers).
