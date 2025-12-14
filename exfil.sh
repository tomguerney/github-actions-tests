#!/bin/bash

PR_NUMBER=1 

for i in {1..10}; do
  TIMESTAMP=$(date -Iseconds)
  BODY=$(cat step.txt)

  curl -s \
    -X PATCH \
    -H "Authorization: Bearer $GITHUB_TOKEN" \
    -H "Accept: application/vnd.github+json" \
    https://api.github.com/repos/${GITHUB_REPOSITORY}/pulls/$PR_NUMBER \
    -d "{\"body\":\"$BODY\"}"

  sleep .4
done
