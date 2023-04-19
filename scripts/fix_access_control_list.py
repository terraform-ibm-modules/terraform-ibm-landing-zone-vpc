import os
import logging
import argparse
import requests

def get_bearer_token(refresh_token: str, cloud_base_domain: str = "cloud.ibm.com") -> str:
    url = f"https://iam.{cloud_base_domain}/identity/token"

    payload = {
        "grant_type": "refresh_token",
        "refresh_token": refresh_token,
        "client_id": "bx",
        "client_secret": "bx"
    }

    headers = {"Content-Type": "application/x-www-form-urlencoded"}

    response = requests.request("POST", url, headers=headers, data=payload)

    return response.json().get("access_token")

def get_acl_rules(
    acl_id: str, region: str, access_token: str, cloud_base_domain: str = "cloud.ibm.com"
    ) -> dict:

    url = f"https://{region}.iaas.{cloud_base_domain}/v1/network_acls/{acl_id}/rules"

    parameters = {
        "version": "2023-04-11",
        "generation": "2",
        "limit": "100"
    }
    headers = {
        "Authorization": f"Bearer {access_token}",
    }

    response = requests.request("GET", url, headers=headers, params=parameters)

    logging.debug(response)
    if response.status_code != 200:
        logging.error(response)
        raise Exception(f"Failed to retrieve rules for ACL {acl_id}")

    if len(response.json().get("rules")) == 0:
        return None
    else:
        return response.json().get("rules")

def delete_acl_rule(
    acl_id: str, rule_id: str, region: str, access_token: str, cloud_base_domain: str = "cloud.ibm.com"
):
    url = f"https://{region}.iaas.{cloud_base_domain}/v1/network_acls/{acl_id}/rules/{rule_id}"

    parameters = {
        "version": "2023-04-11",
        "generation": "2"
    }
    headers = {
        "Authorization": f"Bearer {access_token}",
    }   

    response = requests.request("DELETE", url, headers=headers, params=parameters) 
    logging.debug(response)
    if response.status_code != 204:
        logging.error(response)
        raise Exception(f"Failed to delete rule {rule_id} for ACL {acl_id}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="""Removes all rules in an Access Control List (ACL)
Use Case: typically used to remove all rules for the VPC Default ACL
which cannot be terraformed.
For compliance reasons.
"""
    )

    parser.add_argument(
        "--ibmApiRefreshTokenEnvName",
        dest="ibm_refresh_token_env_name",
        action="store",
        help="IBM Cloud IAM refresh token environment variable name",
        required=True,
    )

    parser.add_argument(
        "--acl_id",
        dest="acl_id",
        action="store",
        help="Access Control List ID",
        required=True,
    )

    parser.add_argument(
        "--region",
        "-r",
        dest="region",
        action="store",
        help="region",
        required=True,
    )

    parser.add_argument(
        "--ibmCloudBaseDomain",
        dest="ibm_cloud_base_domain",
        action="store",
        help="IBM Cloud Base domain",
        default="cloud.ibm.com",
        required=False,
    )

    parser.add_argument(
        "--debug", "-d", dest="debug", action="store_true", help="enable debug logging"
    )

    args = parser.parse_args()
    if args.debug:
        logging.basicConfig(level=logging.DEBUG)
        logging.debug("Debug logging enabled")
    else:
        logging.basicConfig(level=logging.INFO)

    # set argument variables
    refresh_token = os.getenv(args.ibm_refresh_token_env_name)
    if not refresh_token:
        logging.warning(
            f"Please set environment variable `{args.ibm_refresh_token_env_name}`,"
            f" or set the flag `--ibmApiRefreshTokenEnvName` to change the environment variable"
        )
        raise Exception(f"Please set environment variable {args.ibm_refresh_token_env_name}")

    ibmcloud_region = args.region
    acl_id = args.acl_id
    ibmcloud_base_domain = args.ibm_cloud_base_domain

    # get access token using refresh
    access_token = get_bearer_token(refresh_token=refresh_token, cloud_base_domain=ibmcloud_base_domain)

    acl_rules = get_acl_rules(
        acl_id=acl_id, region=ibmcloud_region, access_token=access_token, cloud_base_domain=ibmcloud_base_domain
    )

    if acl_rules:
        logging.info(f"Found {len(acl_rules)} to remove in ACL {acl_id}")
        for rule in acl_rules:
            rule_id = rule['id']
            logging.debug(f"Removing rule {rule['id']}")

            delete_acl_rule(
                acl_id=acl_id, rule_id=rule_id, region=ibmcloud_region, access_token=access_token, cloud_base_domain=ibmcloud_base_domain
            )
    else:
        logging.info(f"No rules found for ACL {acl_id}. Nothing to remove")
        