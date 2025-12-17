package test

import (
	"fmt"
	"log"
	"os"
	"strings"
	"testing"

	"github.com/IBM/go-sdk-core/v5/core"
	"github.com/gruntwork-io/terratest/modules/files"
	"github.com/gruntwork-io/terratest/modules/logger"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/require"

	"github.com/stretchr/testify/assert"
	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/cloudinfo"
	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/common"
	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/testaddons"
	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/testhelper"
	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/testschematic"
)

/*
Global variables
*/
const basicExampleTerraformDir = "examples/basic"
const vpcFlowLogsExampleTerraformDir = "examples/vpc-flow-logs"
const landingZoneExampleTerraformDir = "examples/landing_zone"
const hubAndSpokeDelegatedExampleTerraformDir = "examples/hub-spoke-delegated-resolver"
const existingVPCExampleTerraformDir = "examples/existing_vpc"
const specificZoneExampleTerraformDir = "examples/specific-zone-only"
const vpcWithDnsExampleTerraformDir = "examples/vpc-with-dns"
const fullyConfigFlavorDir = "solutions/fully-configurable"

const resourceGroup = "geretain-test-resources"
const yamlLocation = "../common-dev-assets/common-go-assets/common-permanent-resources.yaml"
const terraformVersion = "terraform_v1.12.2" // This should match the version in the ibm_catalog.json

var permanentResources map[string]interface{}

// To verify DNS records creation
var dnsRecordsMap = map[string][]map[string]interface{}{
	"slz.com": {
		{"name": "testA", "type": "A", "rdata": "1.2.3.4", "ttl": 3600},
		{"name": "testAAAA", "type": "AAAA", "rdata": "2001:0db8:0012:0001:3c5e:7354:0000:5db5"},
		{"name": "testCNAME", "type": "CNAME", "rdata": "test.com"},
		{"name": "testTXT", "type": "TXT", "rdata": "textinformation", "ttl": 900},
		{"name": "testMX", "type": "MX", "rdata": "mailserver.test.com", "preference": 10},
		{"name": "testSRV", "type": "SRV", "rdata": "tester.com", "priority": 100, "weight": 100, "port": 8000, "service": "_sip", "protocol": "udp"},
	}}

// To verify DNS zone creation
var dnsZoneMap = []map[string]interface{}{
	{"name": "slz.com"},
}

func TestMain(m *testing.M) {
	// Read the YAML file contents
	var err error
	permanentResources, err = common.LoadMapFromYaml(yamlLocation)
	if err != nil {
		log.Fatal(err)
	}

	os.Exit(m.Run())
}

func setupOptions(t *testing.T, prefix string, terraformDir string) *testhelper.TestOptions {
	options := testhelper.TestOptionsDefaultWithVars(&testhelper.TestOptions{
		Testing:       t,
		TerraformDir:  terraformDir,
		Prefix:        prefix,
		ResourceGroup: resourceGroup,
		TerraformVars: map[string]interface{}{
			"access_tags": permanentResources["accessTags"],
		},
	})

	return options
}

func TestRunVPCFlowLogsExample(t *testing.T) {
	t.Parallel()

	options := setupOptions(t, "slz-vpc", vpcFlowLogsExampleTerraformDir)

	output, err := options.RunTestConsistency()
	assert.Nil(t, err, "This should not have errored")
	assert.NotNil(t, output, "Expected some output")

	expectedOutputs := []string{"vpc_data"}
	missingOutputs, outputErr := testhelper.ValidateTerraformOutputs(options.LastTestTerraformOutputs, expectedOutputs...)
	assert.Empty(t, outputErr, fmt.Sprintf("Missing expected outputs: %s", missingOutputs))
}

func TestRunLandingZoneExample(t *testing.T) {
	t.Parallel()

	options := setupOptions(t, "slz", landingZoneExampleTerraformDir)

	output, err := options.RunTestConsistency()
	assert.Nil(t, err, "This should not have errored")
	assert.NotNil(t, output, "Expected some output")
}

// Test the fully-configurable DA with defaults (no flow logs)
func TestFullyConfigurable(t *testing.T) {
	t.Parallel()

	options := testschematic.TestSchematicOptionsDefault(&testschematic.TestSchematicOptions{
		Testing: t,
		Region:  "eu-de",
		Prefix:  "vpc-da",
		TarIncludePatterns: []string{
			"*.tf",
			"dynamic_values/*.tf",
			"dynamic_values/config_modules/*/*.tf",
			fullyConfigFlavorDir + "/*.tf",
		},
		TemplateFolder:         fullyConfigFlavorDir,
		Tags:                   []string{"vpc-da-test"},
		DeleteWorkspaceOnFail:  false,
		WaitJobCompleteMinutes: 120,
		TerraformVersion:       terraformVersion,
	})

	options.TerraformVars = []testschematic.TestSchematicTerraformVar{
		{Name: "ibmcloud_api_key", Value: options.RequiredEnvironmentVars["TF_VAR_ibmcloud_api_key"], DataType: "string", Secure: true},
		{Name: "existing_resource_group_name", Value: resourceGroup, DataType: "string"},
		{Name: "region", Value: options.Region, DataType: "string"},
		{Name: "resource_tags", Value: options.Tags, DataType: "list(string)"},
		{Name: "access_tags", Value: permanentResources["accessTags"], DataType: "list(string)"},
		{Name: "prefix", Value: options.Prefix, DataType: "string"},
	}

	err := options.RunSchematicTest()
	assert.Nil(t, err, "This should not have errored")
}

func validateEnvVariable(t *testing.T, varName string) string {
	val, present := os.LookupEnv(varName)
	require.True(t, present, "%s environment variable not set", varName)
	require.NotEqual(t, "", val, "%s environment variable is empty", varName)
	return val
}

func setupTerraform(t *testing.T, prefix, realTerraformDir string) *terraform.Options {
	tempTerraformDir, err := files.CopyTerraformFolderToTemp(realTerraformDir, prefix)
	require.NoError(t, err, "Failed to create temporary Terraform folder")
	apiKey := validateEnvVariable(t, "TF_VAR_ibmcloud_api_key") // pragma: allowlist secret
	region, err := testhelper.GetBestVpcRegion(apiKey, "../common-dev-assets/common-go-assets/cloudinfo-region-vpc-gen2-prefs.yaml", "eu-de")
	require.NoError(t, err, "Failed to get best VPC region")

	existingTerraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: tempTerraformDir,
		Vars: map[string]interface{}{
			"prefix":     prefix,
			"region":     region,
			"create_vpc": false,
			"create_db":  true,
		},
		// Set Upgrade to true to ensure latest version of providers and modules are used by terratest.
		// This is the same as setting the -upgrade=true flag with terraform.
		Upgrade: true,
	})

	terraform.WorkspaceSelectOrNew(t, existingTerraformOptions, prefix)
	_, err = terraform.InitAndApplyE(t, existingTerraformOptions)
	require.NoError(t, err, "Init and Apply of temp existing resource failed")

	return existingTerraformOptions
}

func cleanupTerraform(t *testing.T, options *terraform.Options, prefix string) {
	if t.Failed() && strings.ToLower(os.Getenv("DO_NOT_DESTROY_ON_FAILURE")) == "true" {
		fmt.Println("Terratest failed. Debug the test and delete resources manually.")
		return
	}
	logger.Log(t, "START: Destroy (existing resources)")
	terraform.Destroy(t, options)
	terraform.WorkspaceDelete(t, options, prefix)
	logger.Log(t, "END: Destroy (existing resources)")
}

func TestFullyConfigurableWithFlowLogs(t *testing.T) {
	t.Parallel()

	// Provision resources first

	// Verify ibmcloud_api_key variable is set
	checkVariable := "TF_VAR_ibmcloud_api_key"
	val, present := os.LookupEnv(checkVariable)
	require.True(t, present, checkVariable+" environment variable not set")
	require.NotEqual(t, "", val, checkVariable+" environment variable is empty")

	prefix := fmt.Sprintf("vpc-f-%s", strings.ToLower(random.UniqueId()))
	existingTerraformOptions := setupTerraform(t, prefix, "./existing-resources")

	options := testschematic.TestSchematicOptionsDefault(&testschematic.TestSchematicOptions{
		Testing: t,
		Region:  "eu-de", // Hardcoding region to avoid jp-osa, as jp-osa does not support COS association with HPCS.
		Prefix:  prefix,
		TarIncludePatterns: []string{
			"*.tf",
			"dynamic_values/*.tf",
			"dynamic_values/config_modules/*/*.tf",
			fullyConfigFlavorDir + "/*.tf",
		},
		TemplateFolder:         fullyConfigFlavorDir,
		Tags:                   []string{"vpc-da-test"},
		DeleteWorkspaceOnFail:  false,
		WaitJobCompleteMinutes: 120,
		TerraformVersion:       terraformVersion,
	})

	options.TerraformVars = []testschematic.TestSchematicTerraformVar{
		{Name: "ibmcloud_api_key", Value: options.RequiredEnvironmentVars["TF_VAR_ibmcloud_api_key"], DataType: "string", Secure: true},
		{Name: "existing_resource_group_name", Value: resourceGroup, DataType: "string"},
		{Name: "region", Value: options.Region, DataType: "string"},
		{Name: "resource_tags", Value: options.Tags, DataType: "list(string)"},
		{Name: "access_tags", Value: permanentResources["accessTags"], DataType: "list(string)"},
		{Name: "prefix", Value: options.Prefix, DataType: "string"},
		{Name: "enable_vpc_flow_logs", Value: "true", DataType: "bool"},
		{Name: "existing_cos_instance_crn", Value: permanentResources["general_test_storage_cos_instance_crn"], DataType: "string"},
		{Name: "kms_encryption_enabled_bucket", Value: "true", DataType: "bool"},
		{Name: "existing_kms_instance_crn", Value: permanentResources["hpcs_south_crn"], DataType: "string"},
		{Name: "vpe_gateway_cloud_services", Value: []map[string]string{{"service_name": "kms"}, {"service_name": "cloud-object-storage"}}, DataType: "list(object{})"},
		{Name: "vpe_gateway_cloud_service_by_crn", Value: []map[string]string{{"crn": terraform.Output(t, existingTerraformOptions, "postgresql_db_crn"), "vpe_name": "pg"}}, DataType: "list(object{})"},
		{Name: "vpn_gateways", Value: []map[string]string{{"name": options.Prefix + "-vpn", "subnet_name": "subnet-c"}}, DataType: "list(object{})"},
	}

	require.NoError(t, options.RunSchematicTest(), "This should not have errored")
	cleanupTerraform(t, existingTerraformOptions, prefix)
}

// Test the upgrade of fully-configurable DA with defaults
func TestRunUpgradeFullyConfigurable(t *testing.T) {
	t.Parallel()

	// Verify ibmcloud_api_key variable is set
	checkVariable := "TF_VAR_ibmcloud_api_key"
	val, present := os.LookupEnv(checkVariable)
	require.True(t, present, checkVariable+" environment variable not set")
	require.NotEqual(t, "", val, checkVariable+" environment variable is empty")

	prefix := fmt.Sprintf("vpc-u-%s", strings.ToLower(random.UniqueId()))
	existingTerraformOptions := setupTerraform(t, prefix, "./existing-resources")

	options := testschematic.TestSchematicOptionsDefault(&testschematic.TestSchematicOptions{
		Testing: t,
		Region:  "eu-de", // Hardcoding region to avoid jp-osa, as jp-osa does not support COS association with HPCS.
		Prefix:  prefix,
		TarIncludePatterns: []string{
			"*.tf",
			"dynamic_values/*.tf",
			"dynamic_values/config_modules/*/*.tf",
			fullyConfigFlavorDir + "/*.tf",
		},
		TemplateFolder:             fullyConfigFlavorDir,
		Tags:                       []string{"vpc-da-test"},
		DeleteWorkspaceOnFail:      false,
		WaitJobCompleteMinutes:     120,
		CheckApplyResultForUpgrade: true,
		TerraformVersion:           terraformVersion,
	})

	options.TerraformVars = []testschematic.TestSchematicTerraformVar{
		{Name: "ibmcloud_api_key", Value: options.RequiredEnvironmentVars["TF_VAR_ibmcloud_api_key"], DataType: "string", Secure: true},
		{Name: "existing_resource_group_name", Value: resourceGroup, DataType: "string"},
		{Name: "region", Value: options.Region, DataType: "string"},
		{Name: "resource_tags", Value: options.Tags, DataType: "list(string)"},
		{Name: "access_tags", Value: permanentResources["accessTags"], DataType: "list(string)"},
		{Name: "prefix", Value: options.Prefix, DataType: "string"},
		{Name: "enable_vpc_flow_logs", Value: "true", DataType: "bool"},
		{Name: "existing_cos_instance_crn", Value: permanentResources["general_test_storage_cos_instance_crn"], DataType: "string"},
		{Name: "kms_encryption_enabled_bucket", Value: "true", DataType: "bool"},
		{Name: "existing_kms_instance_crn", Value: permanentResources["hpcs_south_crn"], DataType: "string"},
		{Name: "vpe_gateway_cloud_services", Value: []map[string]string{{"service_name": "kms"}, {"service_name": "cloud-object-storage"}}, DataType: "list(object{})"},
		{Name: "vpe_gateway_cloud_service_by_crn", Value: []map[string]string{{"crn": terraform.Output(t, existingTerraformOptions, "postgresql_db_crn"), "vpe_name": "pg"}}, DataType: "list(object{})"},
		{Name: "vpn_gateways", Value: []map[string]string{{"name": options.Prefix + "-vpn", "subnet_name": "subnet-c"}}, DataType: "list(object{})"},
	}

	err := options.RunSchematicUpgradeTest()
	if !options.UpgradeTestSkipped {
		assert.Nil(t, err, "This should not have errored")
	}
	cleanupTerraform(t, existingTerraformOptions, prefix)
}

func TestRunHubAndSpokeDelegatedExample(t *testing.T) {
	t.Parallel()

	options := testhelper.TestOptionsDefaultWithVars(&testhelper.TestOptions{
		Testing:       t,
		TerraformDir:  hubAndSpokeDelegatedExampleTerraformDir,
		Prefix:        "has-slz",
		ResourceGroup: resourceGroup,
		Region:        "us-south",
		PostApplyHook: func(options *testhelper.TestOptions) error {
			terraformOptions := options.TerraformOptions
			terraformOptions.Vars["update_delegated_resolver"] = true
			_, err := terraform.ApplyE(options.Testing, terraformOptions)
			return err
		},
	})

	output, err := options.RunTestConsistency()
	assert.Nil(t, err, "This should not have errored")
	assert.NotNil(t, output, "Expected some output")
}

func TestVpcAddonDefaultConfiguration(t *testing.T) {
	t.Parallel()

	options := testaddons.TestAddonsOptionsDefault(&testaddons.TestAddonOptions{
		Testing:       t,
		Prefix:        "vpc-ad",
		ResourceGroup: resourceGroup,
		QuietMode:     false, // Suppress logs except on failure
	})

	options.AddonConfig = cloudinfo.NewAddonConfigTerraform(
		options.Prefix,
		"deploy-arch-ibm-slz-vpc",
		"fully-configurable",
		map[string]interface{}{
			"region": "us-south",
		},
	)

	// Disable target / route creation to prevent hitting quota in account
	options.AddonConfig.Dependencies = []cloudinfo.AddonConfig{
		{
			OfferingName:   "deploy-arch-ibm-cloud-monitoring",
			OfferingFlavor: "fully-configurable",
			Inputs: map[string]interface{}{
				"enable_metrics_routing_to_cloud_monitoring": false,
			},
			Enabled: core.BoolPtr(true),
		},
		{
			OfferingName:   "deploy-arch-ibm-activity-tracker",
			OfferingFlavor: "fully-configurable",
			Inputs: map[string]interface{}{
				"enable_activity_tracker_event_routing_to_cloud_logs": false,
			},
			Enabled: core.BoolPtr(true),
		},
	}

	err := options.RunAddonTest()
	require.NoError(t, err)
}
