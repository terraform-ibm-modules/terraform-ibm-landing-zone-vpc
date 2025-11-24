// Tests in this file are run in the PR pipeline
package test

import (
	"fmt"
	"github.com/gruntwork-io/terratest/modules/files"
	"github.com/gruntwork-io/terratest/modules/logger"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/require"
	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/common"
	"os"
	"strings"
	"testing"

	"github.com/IBM/go-sdk-core/v5/core"
	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/cloudinfo"
	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/testaddons"
	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/testhelper"

	"github.com/stretchr/testify/assert"
)

func TestRunBasicExample(t *testing.T) {
	t.Parallel()

	options := testhelper.TestOptionsDefaultWithVars(&testhelper.TestOptions{
		Testing:       t,
		TerraformDir:  basicExampleTerraformDir,
		Prefix:        "bas-slz",
		ResourceGroup: resourceGroup,
	})

	output, err := options.RunTestConsistency()
	assert.Nil(t, err, "This should not have errored")
	assert.NotNil(t, output, "Expected some output")
}

func TestRunNoPrefixVPCFlowLogsExample(t *testing.T) {
	t.Parallel()

	options := setupOptions(t, "slz-vpc-np", vpcFlowLogsExampleTerraformDir)
	options.TerraformVars["use_prefix"] = false

	output, err := options.RunTestConsistency()
	assert.Nil(t, err, "This should not have errored")
	assert.NotNil(t, output, "Expected some output")

	expectedOutputs := []string{"vpc_data"}
	missingOutputs, outputErr := testhelper.ValidateTerraformOutputs(options.LastTestTerraformOutputs, expectedOutputs...)
	assert.Empty(t, outputErr, fmt.Sprintf("Missing expected outputs: %s", missingOutputs))
}

func TestRunSpecificZoneExample(t *testing.T) {
	t.Parallel()

	options := testhelper.TestOptionsDefaultWithVars(&testhelper.TestOptions{
		Testing:       t,
		TerraformDir:  specificZoneExampleTerraformDir,
		Prefix:        "spec-zone-slz",
		ResourceGroup: resourceGroup,
	})

	output, err := options.RunTestConsistency()
	assert.Nil(t, err, "This should not have errored")
	assert.NotNil(t, output, "Expected some output")
}

func TestAddonPermutations(t *testing.T) {
	t.Parallel()

	testCases := []testaddons.AddonTestCase{
		{
			Name:   "no-addons",
			Prefix: "no-addons",
			Dependencies: []cloudinfo.AddonConfig{
				{
					OfferingName:   "deploy-arch-ibm-kms",
					OfferingFlavor: "fully-configurable",
					Enabled:        core.BoolPtr(false),
				},
				{
					OfferingName:   "deploy-arch-ibm-cloud-logs",
					OfferingFlavor: "fully-configurable",
					Enabled:        core.BoolPtr(false),
				},
				{
					OfferingName:   "deploy-arch-ibm-cloud-monitoring",
					OfferingFlavor: "fully-configurable",
					Enabled:        core.BoolPtr(false),
				},
				{
					OfferingName:   "deploy-arch-ibm-activity-tracker",
					OfferingFlavor: "fully-configurable",
					Enabled:        core.BoolPtr(false),
				},
				{
					OfferingName:   "deploy-arch-ibm-scc-workload-protection",
					OfferingFlavor: "fully-configurable",
					Enabled:        core.BoolPtr(false),
				},
			},
		},
		{
			Name:   "all-addons",
			Prefix: "all-addons",
			Dependencies: []cloudinfo.AddonConfig{
				{
					OfferingName:   "deploy-arch-ibm-kms",
					OfferingFlavor: "fully-configurable",
					Enabled:        core.BoolPtr(true),
				},
				{
					OfferingName:   "deploy-arch-ibm-cos",
					OfferingFlavor: "instance",
					Enabled:        core.BoolPtr(true),
				},
				{
					OfferingName:   "deploy-arch-ibm-cloud-logs",
					OfferingFlavor: "fully-configurable",
					Enabled:        core.BoolPtr(true),
				},
				{
					OfferingName:   "deploy-arch-ibm-cloud-monitoring",
					OfferingFlavor: "fully-configurable",
					Enabled:        core.BoolPtr(true),
				},
				{
					OfferingName:   "deploy-arch-ibm-activity-tracker",
					OfferingFlavor: "fully-configurable",
					Enabled:        core.BoolPtr(true),
				},
				{
					OfferingName:   "deploy-arch-ibm-scc-workload-protection",
					OfferingFlavor: "fully-configurable",
					Enabled:        core.BoolPtr(true),
				},
			},
		},
		{
			Name:   "observability-with-no-deps",
			Prefix: "obs-no-dep",
			Dependencies: []cloudinfo.AddonConfig{
				{
					OfferingName:   "deploy-arch-ibm-kms",
					OfferingFlavor: "fully-configurable",
					Enabled:        core.BoolPtr(false),
				},
				{
					OfferingName:   "deploy-arch-ibm-cloud-logs",
					OfferingFlavor: "fully-configurable",
					Enabled:        core.BoolPtr(true),
				},
				{
					OfferingName:   "deploy-arch-ibm-cloud-monitoring",
					OfferingFlavor: "fully-configurable",
					Enabled:        core.BoolPtr(true),
				},
				{
					OfferingName:   "deploy-arch-ibm-activity-tracker",
					OfferingFlavor: "fully-configurable",
					Enabled:        core.BoolPtr(true),
				},
				{
					OfferingName:   "deploy-arch-ibm-scc-workload-protection",
					OfferingFlavor: "fully-configurable",
					Enabled:        core.BoolPtr(false),
				},
				{
					OfferingName:   "deploy-arch-ibm-event-notifications",
					OfferingFlavor: "fully-configurable",
					Enabled:        core.BoolPtr(false),
				},
			},
		},
	}

	baseOptions := testaddons.TestAddonsOptionsDefault(&testaddons.TestAddonOptions{
		Testing:              t,
		ResourceGroup:        resourceGroup,
		QuietMode:            true,
		DeployTimeoutMinutes: 240,
	})

	matrix := testaddons.AddonTestMatrix{
		BaseOptions: baseOptions,
		TestCases:   testCases,
		BaseSetupFunc: func(baseOptions *testaddons.TestAddonOptions, testCase testaddons.AddonTestCase) *testaddons.TestAddonOptions {
			return testaddons.TestAddonsOptionsDefault(&testaddons.TestAddonOptions{
				Testing:          t,
				Prefix:           testCase.Prefix,
				ResourceGroup:    resourceGroup,
				VerboseOnFailure: true,
			})
		},
		AddonConfigFunc: func(options *testaddons.TestAddonOptions, testCase testaddons.AddonTestCase) cloudinfo.AddonConfig {
			return cloudinfo.NewAddonConfigTerraform(
				options.Prefix,
				"deploy-arch-ibm-slz-vpc",
				"fully-configurable",
				map[string]interface{}{},
			)
		},
	}

	baseOptions.RunAddonTestMatrix(matrix)
}

func TestRunExistingVPCExample(t *testing.T) {
	t.Parallel()

	prefix := fmt.Sprintf("existing-vpc-test-%s", strings.ToLower(random.UniqueId()))
	realTerraformDir := "./existing-resources"
	tempTerraformDir, _ := files.CopyTerraformFolderToTemp(realTerraformDir, fmt.Sprintf(prefix+"-%s", strings.ToLower(random.UniqueId())))
	tags := common.GetTagsFromTravis()

	// Verify ibmcloud_api_key variable is set
	checkVariable := "TF_VAR_ibmcloud_api_key"
	val, present := os.LookupEnv(checkVariable)
	require.True(t, present, checkVariable+" environment variable not set")
	require.NotEqual(t, "", val, checkVariable+" environment variable is empty")

	// Programmatically determine region to use based on availability
	region, _ := testhelper.GetBestVpcRegion(val, "../common-dev-assets/common-go-assets/cloudinfo-region-vpc-gen2-prefs.yaml", "eu-de")

	logger.Log(t, "Tempdir: ", tempTerraformDir)
	existingTerraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: tempTerraformDir,
		Vars: map[string]interface{}{
			"prefix":        prefix,
			"region":        region,
			"resource_tags": tags,
		},
		// Set Upgrade to true to ensure latest version of providers and modules are used by terratest.
		// This is the same as setting the -upgrade=true flag with terraform.
		Upgrade: true,
	})

	terraform.WorkspaceSelectOrNew(t, existingTerraformOptions, prefix)
	_, existErr := terraform.InitAndApplyE(t, existingTerraformOptions)
	if existErr != nil {
		assert.True(t, existErr == nil, "Init and Apply of temp existing resource failed")
	} else {

		options := testhelper.TestOptionsDefault(&testhelper.TestOptions{
			Testing:      t,
			TerraformDir: existingVPCExampleTerraformDir,
		})

		options.TerraformVars = map[string]interface{}{
			"region":                       region,
			"vpc_id":                       terraform.Output(t, existingTerraformOptions, "vpc_id"),
			"subnet_ids":                   terraform.OutputJson(t, existingTerraformOptions, "subnet_id"),
			"public_gateway_name":          fmt.Sprintf("%s-public-gateway", prefix),
			"existing_resource_group_name": fmt.Sprintf("%s-resource-group", prefix),
			"name":                         prefix,
		}

		output, err := options.RunTestConsistency()
		assert.Nil(t, err, "This should not have errored")
		assert.NotNil(t, output, "Expected some output")
	}

	// Check if "DO_NOT_DESTROY_ON_FAILURE" is set
	envVal, _ := os.LookupEnv("DO_NOT_DESTROY_ON_FAILURE")
	// Destroy the temporary existing resources if required
	if t.Failed() && strings.ToLower(envVal) == "true" {
		fmt.Println("Terratest failed. Debug the test and delete resources manually.")
	} else {
		logger.Log(t, "START: Destroy (existing resources)")
		terraform.Destroy(t, existingTerraformOptions)
		terraform.WorkspaceDelete(t, existingTerraformOptions, prefix)
		logger.Log(t, "END: Destroy (existing resources)")
	}
}
