#!/bin/bash

source $(dirname "${BASH_SOURCE[0]}")/bot-pr-comment-base.sh

if [[ "$PR_MERGED" == "true" ]]; then
  bot_error "PR already merged!"
fi

git remote set-url origin "$BASE_URL"
git remote add fork "$HEAD_URL"

# make sure branches are up-to-date
git fetch origin $BASE_BRANCH
git fetch fork $HEAD_BRANCH

git config user.email "bot@upsj.de"
git config user.name "Bot"

LOCAL_BRANCH=format-tmp-$HEAD_BRANCH
git checkout -b $LOCAL_BRANCH fork/$HEAD_BRANCH

# format all files
dev_tools/scripts/add_license.sh
dev_tools/scripts/update_ginkgo_header.sh
dev_tools/scripts/format_header.sh
find benchmark common core cuda dpcpp examples hip include omp reference test_install \
  -name '*.cpp' -or -name '*.hpp' -or -name '*.cu' -or -name '*.cuh' \
  -exec clang-format-8 -i {} \;

# check for changed files
LIST_FILES=$(git diff --name-only)

# commit changes if necessary
if [[ "$LIST_FILES" != "" ]]; then
  git commit -a -m "Format files

Co-authored-by: $USER_COMBINED"
  git push fork $LOCAL_BRANCH:$HEAD_BRANCH 2>&1 || bot_error "Cannot push formatted branch, are edits for maintainers allowed?"
  bot_comment "Formatted the following files:\n"'```'"\n$LIST_FILES\n"'```'
else
  bot_comment "Nothing to format"
fi
