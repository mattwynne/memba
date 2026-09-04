#!/usr/bin/env bash
set -euo pipefail

START_SHA_FILE=".fabro/tmp/review-start-sha.txt"

if [ ! -x bin/dev ]; then
  echo "Missing or non-executable bin/dev" >&2
  exit 1
fi

status=$(git status --short)
if [ -n "$status" ]; then
  echo 'Iteration review requires a clean working tree before review starts.' >&2
  printf '%s\n' "$status" >&2
  exit 1
fi

rm -rf .fabro/tmp
mkdir -p .fabro/tmp

if ! git fetch --quiet origin main:refs/remotes/origin/main; then
  echo 'Could not fetch origin/main before capturing review start SHA.' >&2
  exit 1
fi

if ! git rev-parse --verify --quiet 'origin/main^{commit}' >/dev/null; then
  echo 'Could not resolve origin/main after fetch; cannot capture review start SHA.' >&2
  exit 1
fi

git rev-parse 'origin/main^{commit}' > "$START_SHA_FILE"
echo "Review start SHA (origin/main): $(cat "$START_SHA_FILE")"

PATH="$PWD/bin:$PATH" dev sandbox-check
