package test

import (
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/testhelper"
)

const defaultExampleTerraformDir = "examples/default"
const resourceGroup = "geretain-test-resources"

// The ACL ignores can be removed once we merge this PR (https://github.com/terraform-ibm-modules/terraform-ibm-landing-zone-vpc/pull/471)
var ignoreUpdates = []string{"module.slz_vpc.ibm_is_network_acl.network_acl[\"vpc-acl\"]"}

func setupOptions(t *testing.T, prefix string) *testhelper.TestOptions {
	options := testhelper.TestOptionsDefaultWithVars(&testhelper.TestOptions{
		Testing:       t,
		TerraformDir:  defaultExampleTerraformDir,
		Prefix:        prefix,
		ResourceGroup: resourceGroup,
		IgnoreUpdates: testhelper.Exemptions{
			List: ignoreUpdates,
		},
	})

	return options
}

func TestRunBasicExample(t *testing.T) {
	t.Parallel()

	options := setupOptions(t, "slz-vpc")

	output, err := options.RunTestConsistency()
	assert.Nil(t, err, "This should not have errored")
	assert.NotNil(t, output, "Expected some output")
}

func TestRunUpgradeBasicExample(t *testing.T) {
	// Breaking change in this PR leading to next major version - skip upgrade test
	t.Skip()
	t.Parallel()

	options := setupOptions(t, "slz-vpc-upg")

	output, err := options.RunTestUpgrade()
	if !options.UpgradeTestSkipped {
		assert.Nil(t, err, "This should not have errored")
		assert.NotNil(t, output, "Expected some output")
	}
}
