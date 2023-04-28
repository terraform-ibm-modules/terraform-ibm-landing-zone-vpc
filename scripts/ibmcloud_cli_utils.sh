#!/usr/bin/env bash

set -Eeuo pipefail

function ibmcloud_login ()
{
    region="${1}"
    rg="${2}"
    api_visibility="${3}"

    # Target the resource group and region if passed in
    args=(login --quiet)
    if [[ -n "${rg}" && "${rg}" != "UNSET" ]]; then
        args+=(-g "${rg}")
    fi
    if [[ -n "${region}" && "${region}" != "UNSET" ]]; then
        args+=(-r "${region}")
    else
        args+=(--no-region)
    fi
    # change api to private if visibility not public
    if [[ -n "${api_visibility}" && "${api_visibility}" != "UNSET" && "${api_visibility}" != "public" ]]; then
        args+=(-a "private.cloud.ibm.com" --vpc)
    fi

    # ibmcloud login (with 3 retry attempts)
    total_attempts=3
    i=0
    wait=3
    until [ "$i" -ge $total_attempts ]; do
    ibmcloud "${args[@]}" && break
    i=$((i+1))
    if [ "$i" = $total_attempts ]; then
        echo "Maximum login attempts reached. Giving up!" >&2
        exit 1
    else
        echo "Error, retrying in ${wait} secs .." >&2
        sleep ${wait}
    fi
    done
}

function setup_temp_config_home ()
{
    if [[ -z "${IBMCLOUD_HOME:-}" ]]; then
        old_home="${HOME}"
    else
        old_home="${IBMCLOUD_HOME}"
    fi

    # Create a temporary home for CLI config, used by both login and further commands.
    # This ensures config separation between various terraform provision blocks on the same machine.
    ibmcloud_config_home=$(mktemp -d)
    export IBMCLOUD_HOME="${ibmcloud_config_home}"
    export TEMP_IBMCLOUD_HOME="${ibmcloud_config_home}"

    # move any installed plugins
    mkdir "${ibmcloud_config_home}/.bluemix"
    cp -r "${old_home}/.bluemix/plugins" "${ibmcloud_config_home}/.bluemix/plugins"
}

function error_handler ()
{
    # on error clean up the temp folder if created
    if [[ -n "${TEMP_IBMCLOUD_HOME:-}" ]]; then
        rm -rf "${TEMP_IBMCLOUD_HOME}" || true
    fi

    exit "$1"
}
