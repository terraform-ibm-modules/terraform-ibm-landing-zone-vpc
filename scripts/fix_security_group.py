import os
import logging
import argparse
import requests

def get_bearer_token(apikey: str, cloud_base_domain: str = "cloud.ibm.com") -> str:
    url = f"https://iam.{cloud_base_domain}/identity/token"

    payload = (
        f"grant_type=urn%3Aibm%3Aparams%3Aoauth%3Agrant-type%3Aapikey&apikey={apikey}"
    )
    headers = {"Content-Type": "application/x-www-form-urlencoded"}

    response = requests.request("POST", url, headers=headers, data=payload)

    return response.json().get("access_token")

def get_security_group_rules(
    sg_id: str, region: str, apikey: str, cloud_base_domain: str = "cloud.ibm.com"
    ) -> dict:

    url = f"https://{region}.iaas.{cloud_base_domain}/v1/security_groups/{sg_id}/rules"

    parameters = {
        "version": "2023-04-11",
        "generation": "2"
    }
    headers = {
        "Authorization": f"Bearer {get_bearer_token(apikey, cloud_base_domain)}",
    }

    response = requests.request("GET", url, headers=headers, params=parameters)

    logging.debug(response)
    if response.status_code != 200:
        logging.error(response)
        raise Exception(f"Failed to retrieve rules for security group {sg_id}")

    if len(response.json().get("rules")) == 0:
        return None
    else:
        return response.json().get("rules")

def delete_security_group_rule(
    sg_id: str, rule_id: str, region: str, apikey: str, cloud_base_domain: str = "cloud.ibm.com"
):
    url = f"https://{region}.iaas.{cloud_base_domain}/v1/security_groups/{sg_id}/rules/{rule_id}"

    parameters = {
        "version": "2023-04-11",
        "generation": "2"
    }
    headers = {
        "Authorization": f"Bearer {get_bearer_token(apikey, cloud_base_domain)}",
    }   

    response = requests.request("DELETE", url, headers=headers, params=parameters) 
    logging.debug(response)
    if response.status_code != 204:
        logging.error(response)
        raise Exception(f"Failed to delete rule {rule_id} for security group {sg_id}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="""Removes all rules in a security group
Use Case: typically used to remove all rules for the VPC Default security groups
which cannot be terraformed.
For compliance reasons.
"""
    )

    parser.add_argument(
        "--ibmApiKeyVariable",
        dest="ibm_api_key_variable",
        action="store",
        help="Environment variable containing IBM Cloud apikey",
        default="TF_VAR_ibmcloud_api_key",
        required=False,
    )

    parser.add_argument(
        "--security_group_id",
        "-s",
        dest="sg_id",
        action="store",
        help="Security Group ID",
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
    ibmcloud_api_key = os.getenv(args.ibm_api_key_variable)
    if not ibmcloud_api_key:
        logging.warning(
            f"Please set environment variable `{args.ibm_api_key_variable}`,"
            f" or set the flag `--ibmApiKeyVariable` to change the environment variable"
        )
        raise Exception(f"Please set environment variable {args.ibm_api_key_variable}")

    ibmcloud_region = args.region
    sg_id = args.sg_id
    ibmcloud_base_domain = args.ibm_cloud_base_domain

    sg_rules = get_security_group_rules(
        sg_id, ibmcloud_region, ibmcloud_api_key, ibmcloud_base_domain
    )

    if sg_rules:
        logging.info(f"Found {len(sg_rules)} to remove in security group {sg_id}")
        for rule in sg_rules:
            rule_id = rule['id']
            logging.debug(f"Removing rule {rule['id']}")

            delete_security_group_rule(
                sg_id, rule_id, ibmcloud_region, ibmcloud_api_key, ibmcloud_base_domain
            )
    else:
        logging.info(f"No rules found for security group {sg_id}. Nothing to remove")
        