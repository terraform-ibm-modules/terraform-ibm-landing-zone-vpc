---

copyright:
  years: 2025
lastupdated: "2025-12-02"

keywords:

subcollection: deployable-reference-architectures

authors:
  - name: "Khuzaima Shakeel"

# The release that the reference architecture describes
version: 1.0.0

# Whether the reference architecture is published to Cloud Docs production.
# When set to false, the file is available only in staging. Default is false.
production: true

# Use if the reference architecture has deployable code.
# Value is the URL to land the user in the IBM Cloud catalog details page
# for the deployable architecture.
# See https://test.cloud.ibm.com/docs/get-coding?topic=get-coding-deploy-button
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
{: toc-version="1.0.0"}

The QuickStart variation of the Cloud foundation for VPC provides a **basic and simple** Virtual Private Cloud (VPC) deployment that requires minimal configuration. It enables users to quickly create a functional network environment on IBM Cloud. This variation is best suited for users who need a **basic VPC configuration** with lightweight networking defaults and support for VPC Flow Logs.


---

## Architecture diagram
{: #ra-vpc-quickstart-architecture}

![Architecture diagram for the QuickStart variation of Cloud foundation for VPC](deployable-architecture-quickstart-vpc.svg "QuickStart VPC architecture"){: caption="QuickStart VPC architecture" caption-side="bottom"}{: external download="deployable-architecture-quickstart-vpc.svg"}


## Components
{: #ra-vpc-quickstart-components}

### VPC architecture decisions
{: #ra-vpc-quickstart-components-arch}

| Requirement | Component | Reasons for choice | Alternative |
|------------|-----------|--------------------|-------------|
| *Provide a basic, ready-to-use VPC with minimal inputs* | Predefined VPC | Deploys a VPC quickly without requiring the user to design the network | Use the fully configurable variation for deeper customization |
| *Create availability-zone redundancy* | Fixed three-zone subnets | One subnet per zone to ensure multi-AZ coverage | Single-zone deployment (not recommended) |
| *Basic traffic governance* | Network profile selector (open, standard, ibm-internal, closed) | Users can choose the desired security posture without written ACL rules | Manually writing custom ACLs |

{: caption="VPC architecture decisions" caption-side="bottom"}

---

### Networking and connectivity decisions
{: #ra-vpc-quickstart-components-connectivity}

| Requirement | Component | Reason | Alternative |
|------------|-----------|--------|-------------|
| *Optional access to the internet* | Public gateways per zone (automatic) | Enabled only for `open` and `standard` profiles | No public gateways for locked-down profiles |
| *Subnet-level traffic control* | Network ACL profiles | Simplifies security without requiring rule definitions | Fully customizable ACLs (in advanced variation) |
| *Instance-level default security* | Default VPC security group | Automatically cleaned when selecting restrictive profiles (`ibm-internal`, `closed`) | Custom security group rules |

{: caption="Networking and connectivity decisions" caption-side="bottom"}

---

### Simplicity and user experience decisions
{: #ra-vpc-quickstart-components-simplicity}

| Requirement | Component | Reasons | Alternative |
|------------|-----------|---------|-------------|
| *Zero-effort deployment* | Predefined subnets + ACL mapping | Users only pick prefix, region, and profile | Manual subnet planning |
| *Security posture options* | User-friendly “Network Profile” options | Shows descriptions and recommendations |  |
| *Observability integration* | VPC Flow Logs  | Enabled via toggle | External log collectors |

{: caption="Simplicity decision points" caption-side="bottom"}

---

## Key features
{: #ra-vpc-quickstart-features}

### Core VPC Setup
- Automatically creates a new VPC with IBM-recommended defaults
- Deploys **one subnet per zone** (three total)

### Built-in Network Profiles
- **Open** – Unrestricted
- **Standard** – SSH/HTTP/HTTPS + IBM internal rules
- **IBM Internal** – No inbound customer traffic
- **Closed** – Fully restricted

### Security & Network Defaults
- ACLs applied according to selected network profile
- Security group automatically cleaned for restrictive profiles
- Public gateways created only when allowed by the profile

### Optional Flow Logs
- Enable VPC Flow Logs to create a COS instance and bucket automatically


---
<!--
## Next steps
{: #ra-vpc-fully-configurable-next-steps}

TODO: Decide what next steps to list, if any

Optional section. Include links to your deployment guide or next steps to get started with the architecture. -->
