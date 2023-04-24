#!/usr/bin/env bash

set -euo pipefail

IBMCLOUD_API_KEY="UNSET"  # pragma: allowlist secret
SG_ID="UNSET"
REGION="UNSET"
API_VISIBILITY="public"

#### BEGIN GETTING INPUT ####
optstring=":k:s:r:v:"
echo "getting input..."
## get values from their appropriate options. This technique eliminates the need to use
## positional arguments which have caused issues in the past.
## Produce error if any of these values are empty, OR if the value is "NOT-FOUND" which
## indicates an error happening in related external data calls earlier.
while getopts ${optstring} arg; do
  case ${arg} in
    k)
      if [[ -z "${OPTARG}" ]]
      then
        echo "ERROR: ibmcloud_api_key not supplied"
        exit 1
      else
        IBMCLOUD_API_KEY="${OPTARG}"
      fi
      ;;
    s)
      if [[ -z "${OPTARG}" ]]
      then
        echo "ERROR: ID of security group not supplied"
        exit 1
      else
        SG_ID="${OPTARG}"
      fi
      ;;
    r)
      if [[ -z "${OPTARG}" ]]
      then
        echo "ERROR: Region not supplied"
        exit 1
      else
        REGION="${OPTARG}"
      fi
      ;;
    v)
      if [[ -z "${OPTARG}" ]]
      then
        echo "ERROR: API Visibility not supplied"
        exit 1
      else
        API_VISIBILITY="${OPTARG}"
      fi
      ;;
  esac
done
#### END GETTING INPUT ####

#### LOGIN ####
attempts=1
login_api="cloud.ibm.com"
if [[ "${API_VISIBILITY}" != "public" ]]
then
    login_api="private.cloud.ibm.com"
fi
until ibmcloud login -q --apikey "${IBMCLOUD_API_KEY}" -r "${REGION}" -a "${login_api}" || [ $attempts -ge 3 ]; do
    attempts=$((attempts+1))
    echo "Error logging in to IBM Cloud CLI..." >&2
    sleep 5
done

#### GET SECURITY GROUP RULE LIST ####
sg_rule_ids=()
while IFS='' read -r line; do sg_rule_ids+=("$line"); done < <(ibmcloud is security-group-rules "${SG_ID}" --output json | jq -r '.[] | .id')
for i in "${sg_rule_ids[@]}"; do
  echo "REMOVING SECURITY GROUP RULE ID: ${i}"
  ibmcloud is security-group-rule-delete "${SG_ID}" "${i}" --force --quiet
done
