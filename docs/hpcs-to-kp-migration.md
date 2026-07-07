# HPCS to Key Protect migration guide

## Overview

This guide describes how to migrate from Hyper Protect Crypto Services (HPCS / `hs-crypto`) Customer
Root Keys (CRKs) to IBM Key Protect Dedicated (`kms`) CRKs for IBM Cloud services managed by Terraform.

The migration applies to any IBM Cloud service whose Terraform resource uses an HPCS CRN as a KMS key
input — for example Cloud Object Storage buckets, ICD databases, Block Storage volumes, Secrets Manager
instances, and others.

The process has two phases:

1. **Phase 1 — Key migration (outside Terraform):** The IBM Key Migration Tool (CRKM) migrates the
   key registration from HPCS to Key Protect. Terraform is not involved in this phase.
2. **Phase 2 — Terraform state reconciliation:** After Phase 1 completes, the Terraform state is
   updated to reflect the new KP key CRN without destroying or recreating the real IBM Cloud resource.

> **Why two phases?** The IBM Terraform provider treats a KMS key change as a destructive operation
> on many resources — it would destroy and recreate the resource if you simply updated the input
> variable. Phase 1 migrates the real-world encryption out-of-band so the resource is already using
> the KP key before Terraform ever sees the change.

For full background on the migration process, see:
- [Key Migration Tool (CRKM)](https://cloud.ibm.com/docs/key-protect?topic=key-protect-migrate-tool)
- [Migrating from HPCS to Key Protect Dedicated](https://cloud.ibm.com/docs/key-protect?topic=key-protect-migrate-st#migrate-hpcs-usage)

---

## Pre-requisites

Before starting, ensure you have:

- [ ] An active IBM Key Protect Dedicated instance in the same account and region as your HPCS instance
- [ ] A root key created in the Key Protect instance to use as the migration target
- [ ] The CRKM migration tool binary — request access via an IBM Support ticket at
      `https://cloud.ibm.com/unifiedsupport/cases/add` referencing
      `https://cloud.ibm.com/docs/key-protect?topic=key-protect-migrate-tool#migrate-tool-download`
- [ ] IAM S2S authorization policies allowing your IBM Cloud service to access the KP instance
- [ ] The IBM Cloud CLI installed and targeted to the correct account and region:
      `ibmcloud target -r <region>`

---

## Phase 1 — Key migration (outside Terraform)

This phase is performed entirely outside Terraform using the CRKM tool. **Do not run Terraform until
Phase 1 is confirmed complete.**

### Step 1 — Set environment variables

```sh
export HPCS_API_ENDPOINT="https://<hpcs-instance-id>.api.<region>.hs-crypto.appdomain.cloud"
export KP_ST_API_ENDPOINT="https://<kp-instance-id>.api.<region>.kms.appdomain.cloud"
export IBMCLOUD_API_KEY="<your-ibm-cloud-api-key>"
export IBMCLOUD_API_KEY_KP_ST="<your-ibm-cloud-api-key>"
```

> If your HPCS and Key Protect instances are in the same account, both API key variables can use the
> same value.

### Step 2 — Create the CSV input file

Create a file named `migration.csv` with **no header row**. Each row maps one source HPCS key CRN to
one target KP key CRN:

```csv
<source-hpcs-key-crn>,<target-kp-key-crn>
```

Example:

```csv
crn:v1:bluemix:public:hs-crypto:us-south:a/<account-id>:<hpcs-instance-id>:key:<hpcs-key-id>,crn:v1:bluemix:public:kms:us-south:a/<account-id>:<kp-instance-id>:key:<kp-key-id>
```

> **Important:** Do not include a header row in the CSV file. The tool will fail to parse the CRNs if
> a header is present.

### Step 3 — Validate the setup

```sh
crkm status migration.csv
```

Expected output before migration:
- HPCS key associations: `1 or more` — your service resource is registered to this key
- KP-ST key associations: `0` — no resources registered yet
- Migration Intent: `No Migration Intent found`

### Step 4 — Check IAM authorization policies

```sh
crkm authz-check migration.csv
```

Expected output: all associations report `MATCH`

If any association reports `NO MATCH`, the tool prints the exact policy JSON needed. Create the missing
policy via the CLI (replace `<service-name>` with your service, e.g. `cloud-object-storage`,
`databases-for-postgresql`, etc.):

```sh
ibmcloud iam authorization-policy-create \
  <service-name> \
  kms \
  Reader \
  --source-service-instance-id <service-instance-guid> \
  --target-service-instance-id <kp-instance-id>
```

> For services that use delegated authorization (ICD, IKS, ROKS, RabbitMQ), ensure the
> `AuthorizationDelegator` role is also included when creating the policy. The `crkm authz-check`
> output will indicate if this is required.

Re-run `crkm authz-check` after creating policies to confirm all associations show `MATCH` before
proceeding.

### Step 5 — Create the migration intent

```sh
crkm create migration.csv
```

Expected output: `Migration Intent created successfully`

### Step 6 — Wait 5 minutes, then sync

```sh
sleep 300
crkm sync migration.csv
```

> Some services (ICD, IKS, ROKS, RabbitMQ) use delegated authorization and require an explicit sync
> event. If the sync output shows the source key already has zero registrations, the migration
> completed before sync ran — this is expected.

### Step 7 — Verify migration is complete

```sh
crkm status migration.csv
```

Expected output:
- HPCS key associations: `0` — migration complete
- KP-ST key associations: increased by the number of migrated resources

> **Do not proceed to Phase 2 until HPCS associations = 0.** If associations have not dropped to zero,
> run `crkm sync migration.csv` again and recheck after a few minutes. Most services complete within
> four hours. Event Streams may take up to one business day.

---

## Phase 2 — Terraform state reconciliation

After Phase 1 confirms HPCS associations = 0, reconcile the Terraform state. The IBM Terraform provider
marks many resources for forced replacement when the KMS key attribute changes — so you cannot simply
update the variable and run `terraform apply`. The general approach is:

1. Remove the affected resource(s) from Terraform state
2. Update the input variable to the KP key CRN
3. Reconcile the resource back into state
4. Verify `terraform plan` shows no changes

> **Reconciliation is service-specific.** The exact steps depend on which IBM Cloud resource is
> managed and how the Terraform provider handles the KMS key attribute for that resource. The steps
> below describe the general pattern and include a concrete example for Cloud Object Storage.

### Step 1 — Run terraform plan first (do not apply)

Before touching state, run a plan to see what Terraform would do if you updated the variable now:

```sh
terraform plan
```

If the plan shows `# forces replacement` on the resource — this confirms the forced replacement
behaviour and means you must follow the reconciliation steps below. **Do not run `terraform apply`
at this point.**

### Step 2 — Identify the affected resource state addresses

Find the Terraform state addresses of the resources that reference the HPCS key:

```sh
terraform state list
```

Look for resources whose type corresponds to the service being migrated. Examples:

| Service | Resource type to look for |
|---|---|
| Cloud Object Storage bucket | `ibm_cos_bucket` |
| ICD database | `ibm_database` |
| Block Storage volume | `ibm_is_volume` |
| Secrets Manager instance | `ibm_resource_instance` (service=secrets-manager) |

### Step 3 — Remove the affected resources from Terraform state

This removes the resources from Terraform's state file only. It does **not** delete the real IBM Cloud
resources or their data.

```sh
terraform state rm '<resource-state-address>'
```

Remove all dependent resources that reference the same bucket or resource CRN (for example, lifecycle
configurations, attachments, or policies that depend on the resource CRN):

```sh
terraform state rm '<dependent-resource-state-address>'
```

> `terraform state rm` is non-destructive. The real IBM Cloud resource continues to exist and operate
> normally. Terraform simply stops tracking it until you reconcile it back.

### Step 4 — Update the input variable

Update the KMS key CRN input variable in your Terraform configuration from the HPCS CRN to the KP CRN:

```hcl
# Before (HPCS)
<kms_key_variable> = "crn:v1:bluemix:public:hs-crypto:<region>:..."

# After (Key Protect)
<kms_key_variable> = "crn:v1:bluemix:public:kms:<region>:..."
```

### Step 5 — Reconcile the resource back into state

The reconciliation method depends on what the Terraform provider supports for the affected resource:

**Option A — terraform import (preferred when supported)**

If the resource supports `terraform import`, import it back using its IBM Cloud resource ID:

```sh
terraform import '<resource-state-address>' '<ibm-cloud-resource-id>'
```

Then verify:

```sh
terraform plan
# Expected: No changes. Your infrastructure matches the configuration.
```

**Option B — terraform apply -target (when import is blocked)**

Some providers or module configurations block `terraform import` due to `for_each` planning errors or
other constraints. In this case, use a targeted apply to recreate the resource in state with the new
KP key CRN:

```sh
terraform apply -target='<resource-state-address>' --auto-approve
```

> When using `-target`, the real IBM Cloud resource must not exist before running this command —
> delete it first if necessary. The resource will be recreated with the KP key CRN and land in state
> correctly.

### Step 6 — Verify no changes are planned

```sh
terraform plan
```

Expected output:

```
No changes. Your infrastructure matches the configuration.
```

If the plan still shows `# forces replacement` — stop, do not apply. Verify that the KP CRN in your
input variable exactly matches the key that was used as the migration target in Phase 1.

---

## Concrete example — Cloud Object Storage flow logs bucket

This example shows the full reconciliation for the COS flow logs bucket in the
`terraform-ibm-landing-zone-vpc` deployable architecture.

### Find the bucket state address

```sh
terraform state list | grep cos_bucket
# module.cos_buckets[0].module.buckets["<prefix>-flow-logs-bucket"].ibm_cos_bucket.cos_bucket[0]
```

### Remove bucket and lifecycle config from state

```sh
terraform state rm \
  'module.cos_buckets[0].module.buckets["<prefix>-flow-logs-bucket"].ibm_cos_bucket.cos_bucket[0]'

terraform state rm \
  'module.cos_buckets[0].module.buckets["<prefix>-flow-logs-bucket"].ibm_cos_bucket_lifecycle_configuration.cos_bucket_lifecycle[0]'
```

### Update the input variable

```hcl
# Before
existing_flow_logs_bucket_kms_key_crn = "crn:v1:bluemix:public:hs-crypto:us-south:..."

# After
existing_flow_logs_bucket_kms_key_crn = "crn:v1:bluemix:public:kms:us-south:..."
```

### Recreate bucket and lifecycle config in state using targeted apply

> `terraform import` is blocked in this module by unrelated `for_each` planning errors, so
> Option B (targeted apply) is used instead.

```sh
terraform apply \
  -target='module.cos_buckets[0].module.buckets["<prefix>-flow-logs-bucket"].ibm_cos_bucket.cos_bucket[0]' \
  --auto-approve

terraform apply \
  -target='module.cos_buckets[0].module.buckets["<prefix>-flow-logs-bucket"].ibm_cos_bucket_lifecycle_configuration.cos_bucket_lifecycle[0]' \
  --auto-approve
```

### Verify

```sh
terraform plan
# No changes. Your infrastructure matches the configuration.
```

---

## Important notes

| Note | Detail |
|---|---|
| **Data is not affected** | The CRKM tool rewraps the service resource's Data Encryption Key (DEK) with the new KP root key. The actual data in the resource is never touched. |
| **Provider forced replacement is expected** | The IBM Terraform provider marks many resources for replacement when the KMS key attribute changes. This is intentional — the reconciliation path above is designed to work around it without destroying the real resource. |
| **Reconciliation is service-specific** | The exact `terraform state rm` and reconciliation commands depend on the service and resource type. The general pattern is the same but the state addresses and resource IDs differ per service. |
| **Do not run `terraform apply` before Phase 1 is complete** | Running apply before CRKM confirms HPCS associations = 0 will cause the provider to attempt resource replacement. |
| **CRKM tool is for internal use only** | The CRKM binary must not be shared with customers. Customers must request access via an IBM Support ticket. |
| **Event Streams timing** | Event Streams migration may take up to one business day after `crkm create`. All other supported services complete within four hours. |
