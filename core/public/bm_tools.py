"""
title: BillionMail Tools
author: Antigravity
author_url: https://mail.moescale.site
git_url: https://github.com/open-webui/open-webui
version: 2.0
description: Generic developer API client for interacting dynamically with any BillionMail platform endpoint.
"""

import os
import urllib.request
import urllib.parse
import json
import ssl

class Tools:
    def __init__(self):
        # Connect locally via the Docker bridge network to bypass domain expiration
        self.api_url = os.environ.get("BILLIONMAIL_API_URL", "http://172.17.0.1:80/api")
        self.token = os.environ.get("BILLIONMAIL_API_TOKEN", "")

    def call_billionmail_api(self, endpoint: str, method: str = "GET", params: dict = None, body: dict = None) -> str:
        """
        Call any live BillionMail API endpoint dynamically.
        Use this tool to fetch templates, list campaigns, check sending stats, get mail logs, check abnormal bounces, or update configurations.
        
        :param endpoint: The API path, e.g., '/email_template/all', '/overview', '/campaign/list', or '/task/list'.
        :param method: The HTTP method to use (GET, POST, PUT, DELETE). Default is GET.
        :param params: Optional dictionary of query parameters to append to the URL.
        :param body: Optional dictionary of JSON payload to send in the request body (for POST/PUT).
        :return: The JSON response string returned by the BillionMail API.
        """
        # Ensure endpoint starts with a slash and does not duplicate '/api'
        clean_endpoint = endpoint.strip()
        if clean_endpoint.startswith("/api"):
            clean_endpoint = clean_endpoint[4:]
        if not clean_endpoint.startswith("/"):
            clean_endpoint = "/" + clean_endpoint
            
        url = f"{self.api_url}{clean_endpoint}"
        
        # Append query parameters if present
        if params:
            # Convert values to strings for url encoding
            clean_params = {k: str(v) for k, v in params.items() if v is not None}
            url += "?" + urllib.parse.urlencode(clean_params)
            
        req = urllib.request.Request(url, method=method.upper())
        req.add_header("Authorization", f"Bearer {self.token}")
        
        if body:
            req.add_header("Content-Type", "application/json")
            req.data = json.dumps(body).encode("utf-8")
            
        ctx = ssl.create_default_context()
        ctx.check_hostname = False
        ctx.verify_mode = ssl.CERT_NONE

        try:
            with urllib.request.urlopen(req, context=ctx) as res:
                resp_bytes = res.read()
                data = json.loads(resp_bytes.decode("utf-8"))
                return json.dumps(data)
        except urllib.error.HTTPError as e:
            return f"BillionMail API returned HTTP {e.code}: {e.read().decode('utf-8')}"
        except Exception as e:
            return f"Failed to connect to BillionMail endpoint '{endpoint}': {e}"
