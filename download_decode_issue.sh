#!/bin/bash

ISSUE_NUM=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
  "https://api.github.com/repos/$GITHUB_REPOSITORY/issues?state=all&sort=created&direction=desc&per_page=1" \
  | jq -r '.[0].number')

echo "Latest issue number: $ISSUE_NUM"

COMMENT_BODY=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
  "https://api.github.com/repos/$GITHUB_REPOSITORY/issues/$ISSUE_NUM/comments" \
  | jq -r '.[-1].body')

echo "Latest comment retrieved, saving to exfil.txt..."
echo "$COMMENT_BODY" > exfil.txt

echo "File created"
ls -lh exfil.txt
