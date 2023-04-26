#!/usr/bin/env bash

set -euo pipefail

ACL_ID="$1"

#### GET ACL RULE LIST ####
rules_json=$(ibmcloud is network-acl-rules "${ACL_ID}" --output json)
rules_list=$(echo ${rules_json} | jq -r '.[] | .id')
acl_rule_ids=()
while IFS='' read -r line; do acl_rule_ids+=("$line"); done <<< ${rules_list}
for i in "${acl_rule_ids[@]}"; do
  ibmcloud is network-acl-rule-delete "${ACL_ID}" "${i}" --force --quiet
done
