// Tests in this file are run in the PR pipeline
package test

import (
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

func TestRunCustomSecurityGroupExample(t *testing.T) {
	t.Parallel()

	options := testhelper.TestOptionsDefaultWithVars(&testhelper.TestOptions{
		Testing:       t,
		TerraformDir:  customSecurityGroupExampleTerraformDir,
		Prefix:        "sg-slz",
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
					OfferingName:   "deploy-arch-ibm-account-infra-base",
					OfferingFlavor: "resource-group-only",
					Enabled:        core.BoolPtr(false),
				},
				{
					OfferingName:   "deploy-arch-ibm-kms",
					OfferingFlavor: "fully-configurable",
					Enabled:        core.BoolPtr(false),
				},
				{
					OfferingName:   "deploy-arch-ibm-cos",
					OfferingFlavor: "instance",
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
					OfferingName:   "deploy-arch-ibm-account-infra-base",
					OfferingFlavor: "resource-group-only",
					Enabled:        core.BoolPtr(true),
				},
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
			Name:   "scc-with-appconfig-disabled",
			Prefix: "scc-no-app",
			Dependencies: []cloudinfo.AddonConfig{
				{
					OfferingName:   "deploy-arch-ibm-account-infra-base",
					OfferingFlavor: "resource-group-only",
					Enabled:        core.BoolPtr(false),
				},
				{
					OfferingName:   "deploy-arch-ibm-kms",
					OfferingFlavor: "fully-configurable",
					Enabled:        core.BoolPtr(false),
				},
				{
					OfferingName:   "deploy-arch-ibm-cos",
					OfferingFlavor: "instance",
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
					Enabled:        core.BoolPtr(true),
					Inputs: map[string]interface{}{
						"app_config_crn": permanentResources["app_config_crn"],
					},
				},
				{
					OfferingName:   "deploy-arch-ibm-apprapp",
					OfferingFlavor: "fully-configurable",
					Enabled:        core.BoolPtr(false),
				},
			},
		},
		{
			Name:   "observability-with-no-deps",
			Prefix: "obs-no-dep",
			Dependencies: []cloudinfo.AddonConfig{
				{
					OfferingName:   "deploy-arch-ibm-account-infra-base",
					OfferingFlavor: "resource-group-only",
					Enabled:        core.BoolPtr(false),
				},
				{
					OfferingName:   "deploy-arch-ibm-kms",
					OfferingFlavor: "fully-configurable",
					Enabled:        core.BoolPtr(false),
				},
				{
					OfferingName:   "deploy-arch-ibm-cos",
					OfferingFlavor: "instance",
					Enabled:        core.BoolPtr(false),
				},
				{
					OfferingName:   "deploy-arch-ibm-cloud-logs",
					OfferingFlavor: "fully-configurable",
					Enabled:        core.BoolPtr(true),
					Inputs: map[string]interface{}{
						"existing_cos_instance_crn": permanentResources["general_test_storage_cos_instance_crn"],
					},
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
					Inputs: map[string]interface{}{
						"existing_cos_instance_crn": permanentResources["general_test_storage_cos_instance_crn"],
					},
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
		Prefix:               "adv-matrix",
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
				map[string]interface{}{
					"prefix": options.Prefix,
					"region": "us-south",
				},
			)
		},
	}

	baseOptions.RunAddonTestMatrix(matrix)
}
