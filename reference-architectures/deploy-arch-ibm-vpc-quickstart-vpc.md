---

copyright:
  years: 2026
lastupdated: "2026-01-20"

keywords:

subcollection: deployable-reference-architectures

authors:
  - name: "Khuzaima Shakeel"

# The release that the reference architecture describes
version: 8.11.0

# Whether the reference architecture is published to Cloud Docs production.
# When set to false, the file is available only in staging. Default is false.
production: true

# Use if the reference architecture has deployable code.
# Value is the URL to land the user in the IBM Cloud catalog details page
# for the deployable architecture.
deployment-url: https://cloud.ibm.com/catalog/architecture/deploy-arch-ibm-slz-vpc-9fc0fa64-27af-4fed-9dce-47b3640ba739-global

docs: https://cloud.ibm.com/docs/secure-infrastructure-vpc

image_source: https://github.com/terraform-ibm-modules/terraform-ibm-landing-zone-vpc/blob/main/reference-architectures/deployable-architecture-quickstart-vpc.svg

related_links:
  - title: "Cloud foundation for VPC (Standard - Integrated setup with configurable services)"
    url: "https://cloud.ibm.com/docs/deployable-reference-architectures?topic=deployable-reference-architectures-vpc-fully-configurable"
    description: "A deployable architecture that provides full control over VPC networking, security, and connectivity components."
  - title: "Cloud foundation for VPC (Standard - Financial Services edition)"
    url: "https://cloud.ibm.com/docs/deployable-reference-architectures?topic=deployable-reference-architectures-vpc-ra"
    description: "A VPC architecture based on IBM Cloud for Financial Services controls."

use-case: Foundational Infrastructure
compliance: None

content-type: reference-architecture

---

{{site.data.keyword.attribute-definition-list}}

# Cloud foundation for VPC – QuickStart (Basic and simple)
{: #vpc-quickstart-ra}
{: toc-content-type="reference-architecture"}
{: toc-industry="CrossIndustry"}
{: toc-use-case="Foundational Infrastructure"}
{: toc-version="8.11.0"}

The QuickStart variation of the Cloud foundation for VPC provides a **basic and simple** Virtual Private Cloud (VPC) deployment that requires minimal configuration. It enables users to quickly create a functional network environment on IBM Cloud. This variation is best suited for users who need a **basic VPC configuration** with lightweight networking defaults and support for VPC Flow Logs.


---

## Architecture diagram
{: #ra-vpc-quickstart-architecture}

![Architecture diagram for the QuickStart variation of Cloud foundation for VPC](deployable-architecture-quickstart-vpc.svg "QuickStart VPC architecture"){: caption="Quickstart variation of Cloud foundation for VPC" caption-side="bottom"}{: external download="deployable-architecture-quickstart-vpc.svg"}

## Design requirements
{: #ra-vpc-qs-design-requirements}

![Design requirements for Cloud foundation for VPC](heat-map-deploy-arch-slz-vpc-quickstart.svg "Design requirements"){: caption="Scope of the design requirements" caption-side="bottom"}


## Requirements
{: #ra-vpc-quickstart-components}

The following table outlines the requirements that are addressed in this architecture.

| Requirement | Component | Reasons for choice | Alternative choice |
|------------|-----------|--------------------|--------------------|
| Provide a basic, ready-to-use VPC with minimal inputs | Predefined VPC | Deploys a VPC quickly without requiring users to design networking components | Use the fully configurable variation for granular control |
| Create availability-zone redundancy | Fixed three-zone subnets | Ensures high availability by provisioning one subnet per zone automatically | Use the fully configurable variation for flexibility |
| Basic traffic governance | Network profile selector (unrestricted, public_web_services, private_only, isolated) | Provides simple, predefined ACL behavior without requiring custom rules | Define custom ACL rules and SG rules manually in the fully configurable variation |

{: caption="QuickStart variation of Cloud foundation for VPC" caption-side="bottom"}


# Key features
{: #ra-vpc-quickstart-features}

## VPC Setup
- Automatically creates a new VPC with IBM-recommended defaults
- Sets up one subnet per zone, resulting in three subnets.

## Built-in Network Profiles

The following network profiles provide predefined security postures by configuring **Network ACLs**, **public gateway access**, and **default security group behavior**. These profiles align exactly with the options exposed in the IBM Cloud catalog UI.

- **Unrestricted (All Traffic Allowed)**
  Allows all inbound and outbound traffic. Suitable for testing or unrestricted workloads.

- **Public Web Services (SSH, HTTP, HTTPS + IBM Cloud Internal)** *(Default)*
  Allows traffic on common service ports (SSH 22, HTTP 80, HTTPS 443), enables IBM Cloud internal connectivity.

- **Private Only (IBM Cloud Internal + VPC)**
  No external/public connectivity. Only IBM internal and VPC connectivity allowed. Intended for internal-only workloads that must not be exposed publicly.
  Learn more: https://cloud.ibm.com/docs/vpc?topic=vpc-about-networking#private-network

- **Isolated (No Network Access)**
  Fully locked-down environment with no inbound or outbound connectivity. Suitable for highly sensitive or isolated security scenarios.


## Security & Network Defaults
- ACLs applied according to the selected network profile
- Security group automatically cleaned for restrictive profiles
- Public gateways created only when allowed by the profile

## Flow Logs
- When enabled, VPC Flow Logs capture network traffic metadata and automatically create an IBM Cloud Object Storage (COS) instance and bucket to store the logs.
