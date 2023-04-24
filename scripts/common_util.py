import gzip
import json
import platform
import urllib.parse
import urllib.request
import urllib.response

COMMON_REST_HEADERS = {
    "User-Agent": f"python-{platform.python_version()}",
    "Accept-Encoding": "gzip, deflate",
    "Accept": "*/*",
    "Connection": "keep-alive",
}


def get_http_response_str(response: urllib.response.addinfourl) -> str:
    if response.info().get("Content-Encoding") == "gzip":
        pagedata = gzip.decompress(response.read())
    elif response.info().get("Content-Encoding") == "deflate":
        pagedata = response.read()
    else:
        pagedata = response.read()

    return pagedata


def get_bearer_token(
    refresh_token: str,
    cloud_base_domain: str = "cloud.ibm.com",
    use_private_endpoint: bool = False,
) -> str:
    private_url_prefix = "private." if use_private_endpoint else ""
    url = f"https://{private_url_prefix}iam.{cloud_base_domain}/identity/token"

    payload = {
        "grant_type": "refresh_token",
        "refresh_token": refresh_token,
        "client_id": "bx",
        "client_secret": "bx",  # pragma: allowlist secret
    }

    headers = {
        "Content-Type": "application/x-www-form-urlencoded",
    }
    headers |= COMMON_REST_HEADERS  # merge in common headers

    data = urllib.parse.urlencode(payload)
    data = data.encode("ascii")
    request = urllib.request.Request(url=url, data=data, headers=headers)

    response = urllib.request.urlopen(request)

    if response.status == 200:
        response_txt = get_http_response_str(response=response)
        return json.loads(response_txt).get("access_token")
    else:
        raise Exception("Failed to retrieve refresh_token")
