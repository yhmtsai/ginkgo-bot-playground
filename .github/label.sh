#!/bin/bash

source $(dirname "${BASH_SOURCE[0]}")/bot-base.sh

echo -n "Collecting information on triggering PR"
PR_URL=$(jq -r .pull_request.url "$GITHUB_EVENT_PATH")
if [[ "$PR_URL" == "null" ]]; then
  echo -n ...
  PR_URL=$(jq -er .issue.pull_request.url "$GITHUB_EVENT_PATH")
  echo -n .
  ISSUE_URL=$(jq -er .issue.url "$GITHUB_EVENT_PATH")
  echo .
else
  echo -n .
  ISSUE_URL=$(jq -er .pull_request.issue_url "$GITHUB_EVENT_PATH")
  echo .
fi

echo "Retrieving PR file list"
PR_FILES=$(api_get "$PR_URL/files?&per_page=1000" | jq -er '.[] | .filename')

echo "Retrieving PR label list"
OLD_LABELS=$(api_get "$ISSUE_URL" | jq -er '[.labels | .[] | .name]')


label_match() {
  if echo "$PR_FILES" | grep -qE "$2"; then
    echo "+[\"$1\"]"
  fi
}

LABELS="[]"
LABELS=$LABELS$(label_match mod:core ^core/)
LABELS=$LABELS$(label_match mod:reference ^reference/)
LABELS=$LABELS$(label_match mod:openmp ^omp/)
LABELS=$LABELS$(label_match mod:cuda '(^cuda/|^common/)')
LABELS=$LABELS$(label_match mod:hip '(^hip/|^common/)')
LABELS=$LABELS$(label_match mod:dpcpp ^dpcpp/)
LABELS=$LABELS$(label_match reg:benchmarking ^benchmark/)
LABELS=$LABELS$(label_match reg:example ^examples/)
LABELS=$LABELS$(label_match reg:build '(cm|CM)ake')
LABELS=$LABELS$(label_match reg:ci-cd '.yml$')
LABELS=$LABELS$(label_match reg:documentation ^doc/)
LABELS=$LABELS$(label_match reg:testing /test/)
LABELS=$LABELS$(label_match reg:helper-scripts ^dev_tools/)
LABELS=$LABELS$(label_match type:factorization /factorization/)
LABELS=$LABELS$(label_match type:matrix-format /matrix/)
LABELS=$LABELS$(label_match type:multigrid /multigrid/)
LABELS=$LABELS$(label_match type:preconditioner /preconditioner/)
LABELS=$LABELS$(label_match type:reordering /reorder/)
LABELS=$LABELS$(label_match type:solver /solver/)
LABELS=$LABELS$(label_match type:stopping-criteria /stop/)

# if all mod: labels present: replace by mod:all
LABELS=$(echo "$LABELS" | sed 's/.*mod:.*mod:.*mod:.*mod:.*mod:[^"]*"\]/[]+["mod:all"]/')

PATCH_BODY=$(jq -rn "{labels:($OLD_LABELS + $LABELS | unique)}")
api_patch "$ISSUE_URL" "$PATCH_BODY" > /dev/null
