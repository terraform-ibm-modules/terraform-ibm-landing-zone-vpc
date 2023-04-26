#!/usr/bin/env bash

set -euo pipefail

SG_ID="$1"

#### GET SECURITY GROUP RULE LIST ####
rules_json=$(ibmcloud is security-group-rules "${SG_ID}" --output json)
rules_list=$(echo ${rules_json} | jq -r '.[] | .id')
sg_rule_ids=()
while IFS='' read -r line; do sg_rule_ids+=("$line"); done <<< ${rules_list}
for i in "${sg_rule_ids[@]}"; do
  ibmcloud is security-group-rule-delete "${SG_ID}" "${i}" --force --quiet
done
