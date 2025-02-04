# VPC with DNS example

A simple example to provision a Secure Landing Zone (SLZ) Virtual Private Cloud (`VPC`) in two zones (Zone1 and Zone2). Allows creation of Domain Name System (`DNS`) `Zones` and `Records` linking the created `VPC` as a permitted network to the `DNS.`

The following resources are provisioned by this example:

* A new `resource group`, if an existing one is not passed in.

* An IBM `Virtual Private Cloud (VPC)` with a publicly exposed subnet.

* Private `DNS zone` which can only be resolved from IBM Cloud's private network.

* `DNS permitted network` - [DNS Service](https://cloud.ibm.com/docs/dns-svcs/getting-started.html) is a global service, hence the permitted networks (for example, a `VPC`) should be added from any IBM Cloud region. This adds the network to the DNS zone, giving the network access to the zone. Maximum of 10 permitted networks can be added to a `DNS zone`. [Learn more](https://cloud.ibm.com/docs/dns-svcs?topic=dns-svcs-managing-permitted-networks&interface=ui)

* `DNS Records` - `DNS Records` make the connection between human-readable names and IP addresses.

> Note: To create a `PTR` type record, you must have an existing `A` or `AAAA` record that is not already associated with another `PTR` record. [Learn More](https://cloud.ibm.com/docs/dns-svcs?topic=dns-svcs-managing-dns-records&interface=ui#ptr-record)
