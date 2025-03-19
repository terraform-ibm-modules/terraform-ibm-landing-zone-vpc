package test

import (
	"fmt"
	"log"
	"os"
	"strings"
	"testing"

	"github.com/gruntwork-io/terratest/modules/files"
	"github.com/gruntwork-io/terratest/modules/logger"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/require"

	"github.com/stretchr/testify/assert"
	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/common"
	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/testhelper"
)

const basicExampleTerraformDir = "examples/basic"
const defaultExampleTerraformDir = "examples/default"
const landingZoneExampleTerraformDir = "examples/landing_zone"
const hubAndSpokeDelegatedExampleTerraformDir = "examples/hub-spoke-delegated-resolver"
const existingVPCExampleTerraformDir = "examples/existing_vpc"
const specificZoneExampleTerraformDir = "examples/specific-zone-only"
const noprefixExampleTerraformDir = "examples/no-prefix"
const vpcWithDnsExampleTerraformDir = "examples/vpc-with-dns"
const resourceGroup = "geretain-test-resources"

// Define a struct with fields that match the structure of the YAML data
const yamlLocation = "../common-dev-assets/common-go-assets/common-permanent-resources.yaml"

var permanentResources map[string]interface{}

// To verify DNS records creation
var dnsRecordsMap = []map[string]interface{}{
	{"name": "testA", "type": "A", "rdata": "1.2.3.4", "ttl": 3600},
	{"name": "testAAAA", "type": "AAAA", "rdata": "2001:0db8:0012:0001:3c5e:7354:0000:5db5"},
	{"name": "testCNAME", "type": "CNAME", "rdata": "test.com"},
	{"name": "testTXT", "type": "TXT", "rdata": "textinformation", "ttl": 900},
	{"name": "testMX", "type": "MX", "rdata": "mailserver.test.com", "preference": 10},
	{"name": "testSRV", "type": "SRV", "rdata": "tester.com", "priority": 100, "weight": 100, "port": 8000, "service": "_sip", "protocol": "udp"},
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

func TestRunDefaultExample(t *testing.T) {
	t.Parallel()

	options := setupOptions(t, "slz-vpc", defaultExampleTerraformDir)

	output, err := options.RunTestConsistency()
	assert.Nil(t, err, "This should not have errored")
	assert.NotNil(t, output, "Expected some output")

	expectedOutputs := []string{"vpc_data"}
	missingOutputs, outputErr := testhelper.ValidateTerraformOutputs(options.LastTestTerraformOutputs, expectedOutputs...)
	assert.Empty(t, outputErr, fmt.Sprintf("Missing expected outputs: %s", missingOutputs))
}

func TestRunNoPrefixExample(t *testing.T) {
	t.Parallel()

	options := setupOptions(t, "no-prefix-lz", noprefixExampleTerraformDir)

	output, err := options.RunTestConsistency()
	assert.Nil(t, err, "This should not have errored")
	assert.NotNil(t, output, "Expected some output")
}

func TestRunLandingZoneExample(t *testing.T) {
	t.Parallel()

	options := setupOptions(t, "slz", landingZoneExampleTerraformDir)

	output, err := options.RunTestConsistency()
	assert.Nil(t, err, "This should not have errored")
	assert.NotNil(t, output, "Expected some output")
}

func TestRunUpgradeDefaultExample(t *testing.T) {

	t.Parallel()

	options := setupOptions(t, "slz-vpc-upg", defaultExampleTerraformDir)

	output, err := options.RunTestUpgrade()
	if !options.UpgradeTestSkipped {
		assert.Nil(t, err, "This should not have errored")
		assert.NotNil(t, output, "Expected some output")
	}
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

func TestRunVpcWithDnsExample(t *testing.T) {
	t.Parallel()

	options := testhelper.TestOptionsDefaultWithVars(&testhelper.TestOptions{
		Testing:       t,
		TerraformDir:  vpcWithDnsExampleTerraformDir,
		Prefix:        "dns-slz",
		ResourceGroup: resourceGroup,
		Region:        "us-south",
	})

	options.TerraformVars["dns_records"] = dnsRecordsMap
	options.TerraformVars["name"] = "test-dns"
	options.TerraformVars["dns_zone_name"] = "slz.com"
	output, err := options.RunTestConsistency()
	assert.Nil(t, err, "This should not have errored")
	assert.NotNil(t, output, "Expected some output")
}
