#!/usr/bin/env bash

set -euo pipefail

source "$(dirname "$0")"/ibmcloud_cli_utils.sh

acl_id="UNSET"
region="UNSET"
rg="UNSET"
api_visibility="UNSET"

#### BEGIN GETTING INPUT ####
optstring=":a:r:g:v:"
echo "getting input..."
## get values from their appropriate options. This technique eliminates the need to use
## positional arguments which have caused issues in the past.
## Produce error if any of these values are empty, OR if the value is "NOT-FOUND" which
## indicates an error happening in related external data calls earlier.
while getopts ${optstring} arg; do
  case ${arg} in
    a)
      if [[ -z "${OPTARG}" ]]
      then
        echo "ERROR: Access Control List ID not supplied" >&2
        exit 1
      else
        acl_id="${OPTARG}"
      fi
      ;;
    r)
      if [[ -z "${OPTARG}" ]]
      then
        echo "ERROR: Region not supplied" >&2
        exit 1
      else
        region="${OPTARG}"
      fi
      ;;
    g)
      if [[ -z "${OPTARG}" ]]
      then
        echo "ERROR: resource group not supplied" >&2
        exit 1
      else
        rg="${OPTARG}"
      fi
      ;;
    v)
      if [[ -z "${OPTARG}" ]]
      then
        echo "ERROR: API Visibility not supplied" >&2
        exit 1
      else
        api_visibility="${OPTARG}"
      fi
      ;;
  esac
done
#### END GETTING INPUT ####

# Ensure $IBMCLOUD_API_KEY is set
if [[ -z $IBMCLOUD_API_KEY ]]; then
    echo "ERROR: Module variable ibmcloud_api_key is not set! Please provide a valid key in terraform input variable for this feature."
    exit 1
fi

# Ensure ACL id was set
if [[ -z "${acl_id}" || "${acl_id}" == "UNSET" ]]; then
    echo "ERROR: Access Control List ID was empty or not supplied!"
    exit 1
fi

# Create a temporary home for CLI config, used by both login and further commands.
# This ensures config separation between various terraform provision blocks on the same machine.
setup_temp_config_home

#### LOGIN to CLI ####
ibmcloud_login "${region}" "${rg}" "${api_visibility}"

#### GET ACL RULE LIST ####
rules_json=$(ibmcloud is network-acl-rules "${acl_id}" --output json)
rules_list=$(echo "${rules_json}" | jq -r '.[] | .id')
acl_rule_ids=()
while IFS='' read -r line; do acl_rule_ids+=("$line"); done <<< "${rules_list}"
for i in "${acl_rule_ids[@]}"; do
  ibmcloud is network-acl-rule-delete "${acl_id}" "${i}" --force --quiet
done
