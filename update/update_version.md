# Updating from v8 to v9

Version 9 of the Landing Zone VPC module changes how **subnets and VPC address prefixes are identified in Terraform state**.  
Subnets and address prefixes now use a **stable, prefix-independent `resource_name`** as the Terraform state key.

In version 9, subnets and address prefixes use a **stable, prefix-independent `resource_name`** as the Terraform state key.

:information_source: **Important:**  
Without migrating existing Terraform state, updating the `prefix` value will result in **subnet and address prefix destruction and recreation**.

Follow the steps below to safely upgrade to version 9 **without recreating networking resources**.

## Before you begin

Make sure you have recent versions of these command-line prerequisites.

- [IBM Cloud CLI](https://cloud.ibm.com/docs/cli?topic=cli-getting-started)
- [IBM Cloud CLI plug-ins](https://cloud.ibm.com/docs/cli?topic=cli-plug-ins):
    - `is` plug-in (vpc-infrastructure)
    - For IBM Schematics deployments: `sch` plug-in (schematics)
- JSON processor `jq` (https://jqlang.github.io/jq/)
- [Curl](). To test whether curl is installed on your system, run the following command:

    ```sh
    curl -V
    ```

    If you need to install curl, see https://everything.curl.dev/install/index.html.

## Select a procedure

Select the procedure that matches where you deployed the code.

- [Deployed with Schematics](#deployed-with-schematics)
- [Local Terraform](#local-terraform)

## Deployed with Schematics

If you deployed your IBM Cloud infrastructure by using Schematics, the `schematics_update_v8_to_v9.sh` script creates a Schematics job. [View the script](schematics_update_v8_to_v9.sh).

### Schematics process

1. Set the environment variables:

    1. Set the IBM Cloud API key that has access to your IBM Cloud project or Schematics workspace. Run the following command:

        ```sh
        export IBMCLOUD_API_KEY="<API-KEY>" #pragma: allowlist secret
        ```

        Replace `<API-KEY>` with the value of your API key.

    1. Find your Schematics workspace ID:
        - If you are using IBM Cloud Projects:
            1. Go to [Projects](https://cloud.ibm.com/projects)
            1. Select the workspace associated with your VPC deployment
            1. Click the **Configurations** tab.
            1. Click the configuration name that is associated with your VPC deployment.
            1. Under **Workspace** copy the ID.

        - If you are not using IBM Cloud Projects:
            1. Go to [Schematics Workspaces](https://cloud.ibm.com/schematics/workspaces)
            1. Select the location that the workspace is in.
            1. Select the workspace associated with your VPC deployment.
            1. Click **Settings**.
            1. Copy the **Workspace ID**.

    1. Run the following command to set the workspace ID as an environment variable:

        ```sh
        export WORKSPACE_ID="<workspace-id>"
        ```

1. Download the script by running this Curl command:

    ```sh
    curl https://raw.githubusercontent.com/terraform-ibm-modules/terraform-ibm-landing-zone-vpc/main/update/schematics_update_v8_to_v9.sh > schematics_update_v8_to_v9.sh
    ```

1. Identify the region where the VPC is deployed.

1. Run the script:

    ```sh
   bash schematics_update_v8_to_v9.sh \
   -w "$WORKSPACE_ID" \
   -r "<region>" \
   [-g "<resource-group>"]
    ```

     -   -w : Schematics workspace ID
     -   -r : Region where the workspace resources are deployed
     -   -g : (Optional) Resource group to target


 The script:

- Pulls the remote Schematics Terraform state
- Detects SLZ VPC subnet and address prefix resources
- Migrates state keys using `ibmcloud schematics state mv`

    

1.  Monitor the status of the job by selecting the workspace from your [Schematics workspaces dashboard](https://cloud.ibm.com/schematics/workspaces).
    - When the job completes successfully, go to the next step.
    - If the job fails, see [Reverting changes](#reverting-changes).

### Apply the changes in Schematics

1. Update your configuration to consume version 9 of the Landing Zone VPC module.
1. In Schematics, click Generate plan and verify:

     - No subnets are destroyed or re-created
     - No address prefixes are destroyed or re-created
     - Only in-place name updates are shown

1. Click Apply plan.

1. If the job is successful, follow the steps in [Clean up](#clean-up). If the job fails, see [Reverting changes](#reverting-changes).

## Local Terraform

If you store both the Terraform code and state file locally, run the `update_v8_to_v9.sh` script locally. [View the script](schematics_update_v8_to_v9.sh).

1. Set the IBM Cloud API key that has access to your VPCs as an environment variable by running the following command:

    ```sh
    export IBMCLOUD_API_KEY="<API-KEY>" #pragma: allowlist secret
    ```

    Replace `<API-KEY>` with the value of your API key.

1. Change to the directory containing your Terraform state file.

1. Download the script to the directory with the state file by running this Curl command:

    ```sh 
    curl https://raw.githubusercontent.com/terraform-ibm-modules/terraform-ibm-landing-zone-vpc/main/update/update_v8_to_v9.sh > update_v8_to_v9.sh
    ```

1. Run the script from the directory with the state file:

    ```sh
    bash update_v8_to_v9.sh
    ```

    The script:

   - Reads the local Terraform state

   - Detects prefix-based subnet and address prefix keys

   - Generates terraform state mv commands

   - Prompts for confirmation before applying changes

   
1. Initialize, check the planned changes, and apply the changes:


    1. Run the `terraform init` command to pull the latest version.
    1. Run the `terraform plan` command to make sure that none of the VPC resources will be re-created.

        - You should see in-place updates to names. No resources should be set to be destroyed or re-created.
       
    1. Run `terraform apply` to upgrade to the 9 version of the module and apply the update in place.
    1. If the commands are successful, follow the steps in [Clean up](#clean-up).

### Expected Terraform plan after migration

#### After migrating the state and updating the prefix value:

- Subnets are updated in place

- Address prefixes are updated in place

- No CIDR changes occur

- No subnet or address prefix resources are re-created


```sh
Example
~ name = "testvpc-vpc-subnet-a" -> "testvpc1-vpc-subnet-a"
```

### Clean up

After a successful migration, remove temporary files created by the script:

```sh
rm moved.json revert.json
```

## Reverting changes

If the script fails, run the script again with the `-z` option to undo the changes. The script uses the `revert.json` file that was created when you ran the script without the `-z` option.

```sh
bash schematics_update_v8_to_v9.sh -z
```

- If you ran the job in Schematics, a new workspace job reverts the state to what existed before you ran the script initially.
- If your code and state file are on your computer, the script reverts changes to the local Terraform state file.

:exclamation: **Important:** After you revert the changes, don't run any other steps in this process. Create an IBM Cloud support case and include information about the script and errors. For more information, see [Creating support cases](https://cloud.ibm.com/docs/get-support?topic=get-support-open-case&interface=ui).