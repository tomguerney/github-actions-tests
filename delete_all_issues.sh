#!/bin/bash
set -euo pipefail

# Requires: gh CLI installed and authentication via GITHUB_TOKEN (we set this to your DELETE_TOKEN in the workflow)

REPO="${GITHUB_REPOSITORY:-}"
if [ -z "$REPO" ]; then
  echo "GITHUB_REPOSITORY is not set. Exiting."
  exit 1
fi

echo "Listing all issues for repo: $REPO"
ISSUES=$(gh issue list --repo "$REPO" --state all --json number -q '.[].number')

if [ -z "$ISSUES" ]; then
  echo "No issues found"
  exit 0
fi

echo "Deleting issues: $ISSUES"

for issue_num in $ISSUES; do
  echo "Deleting issue #$issue_num"
  gh issue delete "$issue_num" --repo "$REPO" --yes
  echo "Deleted #$issue_num"
done

echo "All issues deleted successfully"
