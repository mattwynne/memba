#!/usr/bin/env bash
set -euo pipefail

PLAN_PATH="${1:?plan path required}"
START_LINE="${2:?start line required}"
END_LINE="${3:?end line required}"
MAX_LINES="${4:?max lines required}"
LABEL="${5:-plan chunk}"

if [ ! -f "$PLAN_PATH" ]; then
  echo "Plan file not found: $PLAN_PATH" >&2
  exit 1
fi

TOTAL_LINES="$(wc -l < "$PLAN_PATH" | tr -d ' ')"

printf 'PLAN_PATH=%s\n' "$PLAN_PATH"
printf 'PLAN_TOTAL_LINES=%s\n' "$TOTAL_LINES"
printf 'PLAN_CHUNK=%s\n' "$LABEL"
printf 'PLAN_CHUNK_LINES=%s-%s\n\n' "$START_LINE" "$END_LINE"

if [ "$START_LINE" -le "$TOTAL_LINES" ]; then
  sed -n "${START_LINE},${END_LINE}p" "$PLAN_PATH"
else
  echo "(no plan lines in this chunk)"
fi

if [ "$END_LINE" -ge "$MAX_LINES" ] && [ "$TOTAL_LINES" -gt "$MAX_LINES" ]; then
  echo >&2
  echo "Plan has $TOTAL_LINES lines, exceeding the plan-validation chunk limit of $MAX_LINES lines." >&2
  echo "Increase the workflow chunk coverage before validating this plan so reviewers see the complete text." >&2
  exit 1
fi
