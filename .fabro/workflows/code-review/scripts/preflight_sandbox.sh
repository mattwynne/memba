#!/usr/bin/env bash
set -euo pipefail

START_SHA_FILE=".fabro/tmp/review-start-sha.txt"
CANDIDATE_SHA_FILE=".fabro/tmp/review-candidate-sha.txt"
EXPECTED_CANDIDATE_SHA="${1:?expected review candidate SHA required}"

if [ ! -x bin/dev ]; then
  echo "Missing or non-executable bin/dev" >&2
  exit 1
fi

status=$(git status --short)
if [ -n "$status" ]; then
  echo 'Code review requires a clean working tree before review starts.' >&2
  printf '%s\n' "$status" >&2
  exit 1
fi

rm -rf .fabro/tmp
mkdir -p .fabro/tmp
date +%s > .fabro/tmp/code-review-start-epoch

if ! candidate_sha=$(git rev-parse --verify "$EXPECTED_CANDIDATE_SHA^{commit}" 2>/dev/null); then
  echo "Expected review candidate does not resolve: $EXPECTED_CANDIDATE_SHA" >&2
  exit 1
fi

# Fabro may have checkpointed read_plan before this stage, so HEAD's commit ID
# can differ while its tree must still be the exact tree selected at launch.
head_tree=$(git rev-parse 'HEAD^{tree}')
candidate_tree=$(git rev-parse "$candidate_sha^{tree}")
if [ "$head_tree" != "$candidate_tree" ]; then
  echo 'Review sandbox tree no longer matches the launch candidate; refusing stale or retargeted review.' >&2
  echo "Launch candidate: $candidate_sha ($candidate_tree)" >&2
  echo "Sandbox HEAD: $(git rev-parse HEAD) ($head_tree)" >&2
  exit 1
fi

printf '%s\n' "$candidate_sha" > "$START_SHA_FILE"
printf '%s\n' "$candidate_sha" > "$CANDIDATE_SHA_FILE"
echo "Review candidate SHA (launch HEAD): $candidate_sha"

PATH="$PWD/bin:$PATH" dev sandbox-check
