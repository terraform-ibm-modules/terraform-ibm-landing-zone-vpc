## Configuring network profile input for VPC <a name="network-profile"></a>

This variable lets you choose from predefined network security profiles that control the default **Network ACL behavior**, **public gateway availability**, and whether **default Security Group (SG) rules are cleaned**. It simplifies deployment by offering four security levels ranging from fully open to fully restricted.

- **Variable name:** `network_profile`
- **Type:** `string`
- **Default value:** `"standard"`
- **Allowed values:** `open`, `standard`, `ibm-cloud-private-backbone`, `closed`

The selected profile automatically defines:
The selected network profile automatically defines the following behavior:

| Profile                                   | Default Behavior                                                                 | Public Gateway | Default Security Group Rules |
|-------------------------------------------------------------|----------------------------------------------------------------------------------|----------------|------------------------------|
| **Open (Public & Open Access)**                              | Allows all inbound and outbound traffic                                          | **Enabled**    | Explicit SG rules added: allow all inbound and outbound traffic.               |
| **Standard (Specific Ports & Internal Access)** *(Default)* | Allows inbound access on common service ports (SSH 22, HTTP 80, HTTPS 443), enables IBM Cloud internal connectivity, and permits outbound TCP return traffic required for these services.     | **Enabled**    | Explicit SG rules added: inbound SSH (22), HTTP (80), HTTPS (443). Default SG outbound behavior (allow all outbound) is preserved.               |
| **IBM Cloud private backbone (Private Network Only)**       | No external/public connectivity. Only IBM internal and VPC connectivity allowed. | **Disabled**   | **Cleaned**                  |
| **Closed (Fully Isolated)**                                  | Fully locked-down environment with no inbound or outbound traffic                | **Disabled**   | **Cleaned**                  |


### When to use which profile?

| Scenario / Intent                                                  | Recommended Profile |
|-------------------------------------------------------------------|---------------------|
| Experimenting or testing without restrictions                     | `Open`              |
| Standard workloads that require access on common ports such as SSH, HTTP, and HTTPS. | `Standard`            |
| Internal-only workloads that must communicate only within IBM Cloud using the private backbone network (no public internet exposure). [Learn more](https://cloud.ibm.com/docs/vpc?topic=vpc-private-network-connectivity#:~:text=A%20private%20backbone%20for%20all%20connectivity) | `IBM Cloud private backbone` |
| High-security isolated setups without external communication      | `Closed`            |

---
