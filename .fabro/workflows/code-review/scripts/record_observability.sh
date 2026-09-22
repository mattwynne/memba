#!/usr/bin/env bash
set -euo pipefail

disposition="${1:?disposition required}"
human_paused="${2:?human-paused flag required}"
heal_expected="${3:?heal-expected flag required}"
run_id="${FABRO_RUN_ID:-${FABRO_RUN:-unknown}}"
start_file=.fabro/tmp/code-review-start-epoch
now=$(date +%s)
start=$now
if [ -f "$start_file" ]; then
  start=$(cat "$start_file")
fi
case "$start" in (*[!0-9]*|'') start=$now ;; esac
elapsed=$((now - start))
heal_published=false
if [ "$heal_expected" = true ]; then
  git fetch --quiet origin main:refs/remotes/origin/main || true
  if git log -20 --format='%B' origin/main 2>/dev/null | grep -Fq "Fabro-Run-Id: $run_id"; then
    heal_published=true
  fi
fi
printf 'CODE_REVIEW_OBSERVABILITY run_id=%s disposition=%s human_paused=%s heal_commit_published=%s elapsed_seconds=%s\n' \
  "$run_id" "$disposition" "$human_paused" "$heal_published" "$elapsed"
record=$(printf '{"run_id":"%s","review_disposition":"%s","human_paused":%s,"heal_commit_published":%s,"elapsed_seconds":%s}' \
  "$run_id" "$disposition" "$human_paused" "$heal_published" "$elapsed")
printf '%s\n' "$record"
mkdir -p .fabro/tmp
printf '%s\n' "$record" >> .fabro/tmp/code-review-observability.jsonl
