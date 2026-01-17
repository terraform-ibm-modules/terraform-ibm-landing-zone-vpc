# VPC with DNS example

<!-- BEGIN SCHEMATICS DEPLOY HOOK -->
<a href="https://cloud.ibm.com/schematics/workspaces/create?workspace_name=landing-zone-vpc-vpc-with-dns-example&repository=https://github.com/terraform-ibm-modules/terraform-ibm-landing-zone-vpc/tree/main/examples/vpc-with-dns"><img src="https://img.shields.io/badge/Deploy%20with IBM%20Cloud%20Schematics-0f62fe?logo=ibm&logoColor=white&labelColor=0f62fe" alt="Deploy with IBM Cloud Schematics" style="height: 16px; vertical-align: text-bottom;"></a>
<!-- END SCHEMATICS DEPLOY HOOK -->


A simple example demonstrating the provisioning of a `Secure Landing Zone (SLZ) Virtual Private Cloud (VPC)` across two zones (`Zone 1` and `Zone 2`). This setup includes the creation of `Domain Name System (DNS) Zones and Records`, linking the provisioned VPC as a permitted network for DNS operations.

The following resources are provisioned by this example:

* A new `resource group`, if an existing one is not passed in.

* An IBM `Virtual Private Cloud (VPC)` with a publicly exposed subnet.

* Private `DNS zone` which can only be resolved from IBM Cloud's private network.

* `DNS permitted network` - [DNS Service](https://cloud.ibm.com/docs/dns-svcs/getting-started.html) is a global service, hence the permitted networks (for example, a `VPC`) should be added from any IBM Cloud region. This adds the network to the DNS zone, giving the network access to the zone. Maximum of 10 permitted networks can be added to a `DNS zone`. [Learn more](https://cloud.ibm.com/docs/dns-svcs?topic=dns-svcs-managing-permitted-networks&interface=ui)

* `DNS Records` - `DNS Records` make the connection between human-readable names and IP addresses.

> Note: To create a `PTR` type record, you must have an existing `A` or `AAAA` record that is not already associated with another `PTR` record. [Learn More](https://cloud.ibm.com/docs/dns-svcs?topic=dns-svcs-managing-dns-records&interface=ui#ptr-record)

<!-- BEGIN SCHEMATICS DEPLOY TIP HOOK -->
:information_source: Ctrl/Cmd+Click or right-click on the Schematics deploy button to open in a new tab
<!-- END SCHEMATICS DEPLOY TIP HOOK -->
