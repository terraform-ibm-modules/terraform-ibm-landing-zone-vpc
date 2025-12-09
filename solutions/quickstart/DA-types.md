## Configuring network profile input for VPC <a name="network-profile"></a>

This variable lets you choose from predefined network security profiles that control the default **Network ACL behavior**, **public gateway availability**, and whether **default Security Group (SG) rules are cleaned**. It simplifies deployment by offering four security levels ranging from fully open to fully restricted.

- **Variable name:** `network_profile`
- **Type:** `string`
- **Default value:** `"standard"`
- **Allowed values:** `open`, `standard`, `ibm-internal`, `closed`

The selected profile automatically defines:

| Profile        | Default Behavior                                                  | Public Gateway | Default SG Rules |
|----------------|------------------------------------------------------------------|----------------|------------------|
| `open`         | Allow all inbound and outbound traffic                           | **Enabled**    | **Preserved**    |
| `standard`       | Allow SSH(22), HTTP(80), HTTPS(443) + IBM internal rules         | **Enabled**    | **Preserved**    |
| `ibm-internal` | No customer inbound traffic, only IBM internal + VPC connectivity| **Disabled**   | **Cleaned**      |
| `closed`       | Fully isolated, no inbound or outbound                           | **Disabled**   | **Cleaned**      |

### When to use which profile?

| Scenario / Intent                                                  | Recommended Profile |
|-------------------------------------------------------------------|---------------------|
| Experimenting or testing without restrictions                     | `open`              |
| Standard workloads with internet access and common ports allowed  | `standard`            |
| Internal-only workloads, private environments                     | `ibm-internal`      |
| High-security isolated setups without external communication      | `closed`            |

---

### Examples

```hcl
# Recommended default configuration
network_profile = "standard"
