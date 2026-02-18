#!/bin/bash
CURRENT=$(git rev-parse --abbrev-ref HEAD)
DEFAULT_BRANCH=$(git rev-parse --abbrev-ref origin/HEAD 2>/dev/null | sed 's|origin/||')
DEFAULT_BRANCH="${DEFAULT_BRANCH:-main}"
ARG="$1"

# If a number is passed, use HEAD~N
if [[ "$ARG" =~ ^[0-9]+$ ]]; then
  echo "Mode: last $ARG commits"
  echo "Current branch: $CURRENT"
  echo ""
  echo "=== Changed files ==="
  git diff "HEAD~$ARG" --stat
  echo ""
  echo "=== Full diff ==="
  git diff "HEAD~$ARG"

# If on the default branch (no feature branch to diff), show last 1 commit
elif [ "$CURRENT" = "$DEFAULT_BRANCH" ]; then
  echo "Mode: on default branch ($DEFAULT_BRANCH), showing last commit"
  echo ""
  echo "=== Changed files ==="
  git diff HEAD~1 --stat
  echo ""
  echo "=== Full diff ==="
  git diff HEAD~1

# Otherwise diff current branch against base
else
  BASE="${ARG:-$DEFAULT_BRANCH}"
  echo "Mode: branch diff ($CURRENT vs $BASE)"
  echo ""
  echo "=== Changed files ==="
  git diff "$BASE"...HEAD --stat
  echo ""
  echo "=== Full diff ==="
  git diff "$BASE"...HEAD
fi
