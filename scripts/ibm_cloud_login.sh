#!/usr/bin/env bash

set -eo pipefail

region="UNSET"
rg="UNSET"
api_visibility="UNSET"

#### BEGIN GETTING INPUT ####
optstring=":r:g:v:"
echo "getting input..."
## get values from their appropriate options. This technique eliminates the need to use
## positional arguments which have caused issues in the past.
## Produce error if any of these values are empty, OR if the value is "NOT-FOUND" which
## indicates an error happening in related external data calls earlier.
while getopts ${optstring} arg; do
  case ${arg} in
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

# Target the resource group and region if passed in
cmd="ibmcloud login --quiet"
if [[ -n "${rg}" && "${rg}" != "UNSET" ]]; then
    cmd+=" -g ${rg}"
fi
if [[ -n "${region}" && "${region}" != "UNSET" ]]; then
    cmd+=" -r ${region}"
fi
# change api to private if visibility not public
if [[ -n "${api_visibility}" && "${api_visibility}" != "UNSET" && "${api_visibility}" != "public" ]]; then
    cmd+=" -a 'private.cloud.ibm.com' --vpc"
fi

# ibmcloud login (with 3 retry attempts)
total_attempts=3
i=0
wait=3
until [ "$i" -ge $total_attempts ]; do
  ${cmd} && break
  i=$((i+1))
  if [ "$i" = $total_attempts ]; then
    echo "Maximum login attempts reached. Giving up!" >&2
    exit 1
  else
    echo "Error, retrying in ${wait} secs .." >&2
    sleep ${wait}
  fi
done