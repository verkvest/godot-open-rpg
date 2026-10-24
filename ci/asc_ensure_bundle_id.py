#!/usr/bin/env python3
"""Register the iOS bundle id with App Store Connect if it is missing.

Creates only the bundle id (POST /v1/bundleIds). The App Store Connect app
record cannot be created with this API; TestFlight upload reports that case.
"""

import json
import os
import sys
import time
import urllib.error
import urllib.parse
import urllib.request

import jwt


def main() -> int:
    key_id = os.environ["APPSTORE_API_KEY_ID"]
    issuer = os.environ["APPSTORE_API_ISSUER_ID"]
    key_path = os.environ["ASC_KEY_PATH"]
    bundle_id = os.environ.get("BUNDLE_ID", "es.verkvest.quillfen")
    app_name = os.environ.get("APP_NAME", "Quillfen")

    with open(key_path, "r", encoding="utf-8") as handle:
        private_key = handle.read()

    now = int(time.time())
    token = jwt.encode(
        {"iss": issuer, "iat": now, "exp": now + 900, "aud": "appstoreconnect-v1"},
        private_key,
        algorithm="ES256",
        headers={"kid": key_id, "typ": "JWT"},
    )
    headers = {"Authorization": f"Bearer {token}", "Content-Type": "application/json"}

    query = urllib.parse.urlencode({"filter[identifier]": bundle_id, "limit": 5})
    lookup = urllib.request.Request(
        f"https://api.appstoreconnect.apple.com/v1/bundleIds?{query}",
        headers=headers,
    )
    try:
        with urllib.request.urlopen(lookup) as response:
            payload = json.load(response)
    except urllib.error.HTTPError as error:
        body = error.read().decode("utf-8", "replace")
        print(f"::error::App Store Connect bundle id lookup failed ({error.code}): {body[:800]}")
        return 1

    if payload.get("data"):
        print(f"Bundle id {bundle_id} already registered.")
        return 0

    body = json.dumps({
        "data": {
            "type": "bundleIds",
            "attributes": {
                "identifier": bundle_id,
                "name": app_name,
                "platform": "IOS",
            },
        }
    }).encode("utf-8")
    create = urllib.request.Request(
        "https://api.appstoreconnect.apple.com/v1/bundleIds",
        data=body,
        headers=headers,
        method="POST",
    )
    try:
        with urllib.request.urlopen(create) as response:
            print(f"Registered bundle id {bundle_id} ({response.status}).")
            return 0
    except urllib.error.HTTPError as error:
        detail = error.read().decode("utf-8", "replace")
        if error.code == 409 or "ENTITY_ERROR.DUPLICATE" in detail:
            print(f"Bundle id {bundle_id} already registered.")
            return 0
        print(f"::error::Could not register bundle id {bundle_id} ({error.code}): {detail[:800]}")
        return 1


if __name__ == "__main__":
    sys.exit(main())
