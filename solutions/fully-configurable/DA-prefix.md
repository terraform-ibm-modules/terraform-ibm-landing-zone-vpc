## Prefix in Deployable Architecture

The deployable architecture includes a `prefix` input variable, which is used to prepend a specified string to all resources created by the solution. This helps distinguish and easily locate the resources. If you prefer not to use a prefix, you can set the value to `null` or an empty string.

- Rules: 
  - must begin with a lowercase letter
  - may contain only lowercase letters, digits, and hyphens '-'
  - must not end with a hyphen('-')
  - can not contain consecutive hyphens ('--')
  - maximum length allowed is of 16 characters

### Example

- Prefix can be something like `dev`, `test`, `prod` to help identify the resources across different environments.

- It can include the region name to help identify resources based on their region. Examples are `dev-eu-gb`, `dev-us-south`.



