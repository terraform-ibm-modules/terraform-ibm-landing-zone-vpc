// Tests in this file are run in the PR pipeline
package test

import (
	"testing"

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
