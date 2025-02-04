// Tests in this file are run in the PR pipeline
package test

import (
	"testing"

	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/testhelper"

	"github.com/stretchr/testify/assert"
)

// To verify DNS records creation
var dnsRecordsMap = []map[string]interface{}{
	{"name": "testA", "type": "A", "rdata": "1.2.3.4", "ttl": 3600},
	{"name": "testAAAA", "type": "AAAA", "rdata": "2001:0db8:0012:0001:3c5e:7354:0000:5db5"},
	{"name": "testCNAME", "type": "CNAME", "rdata": "test.com"},
	{"name": "testTXT", "type": "TXT", "rdata": "textinformation", "ttl": 900},
	{"name": "testMX", "type": "MX", "rdata": "mailserver.test.com", "preference": 10},
	{"name": "testSRV", "type": "SRV", "rdata": "tester.com", "priority": 100, "weight": 100, "port": 8000, "service": "_sip", "protocol": "udp"},
}

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

func TestRunHubAndSpokeDelegatedExample(t *testing.T) {
	t.Parallel()

	options := testhelper.TestOptionsDefaultWithVars(&testhelper.TestOptions{
		Testing:       t,
		TerraformDir:  hubAndSpokeDelegatedExampleTerraformDir,
		Prefix:        "has-slz",
		ResourceGroup: resourceGroup,
		Region:        "us-south",
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

func TestRunVpcWithDnsExample(t *testing.T) {
	t.Parallel()

	options := testhelper.TestOptionsDefaultWithVars(&testhelper.TestOptions{
		Testing:       t,
		TerraformDir:  vpcWithDnsExampleTerraformDir,
		Prefix:        "dns-slz",
		ResourceGroup: resourceGroup,
		Region:        "us-south",
	})
	options.TerraformVars = map[string]interface{}{
		"dns_records":   dnsRecordsMap,
		"name":          "test-dns",
		"dns_zone_name": "slz.com",
	}
	output, err := options.RunTestConsistency()
	assert.Nil(t, err, "This should not have errored")
	assert.NotNil(t, output, "Expected some output")
}
