#!/usr/bin/env bash
set -euo pipefail

kind=review
before_head_file=".fabro/tmp/${kind}-repair-before-head.txt"
before=".fabro/tmp/${kind}-repair-before.patch"
after=".fabro/tmp/${kind}-repair-after.patch"

if [ ! -f "$before_head_file" ]; then
  echo "Missing repair baseline HEAD file: $before_head_file" >&2
  exit 1
fi
if [ ! -f "$before" ]; then
  echo "Missing repair baseline patch: $before" >&2
  exit 1
fi

before_head=$(cat "$before_head_file")
if ! git cat-file -e "$before_head^{commit}" 2>/dev/null; then
  echo "Repair baseline HEAD does not resolve: $before_head" >&2
  exit 1
fi

git diff --binary "$before_head" > "$after"
changed_files=$(git diff --name-only "$before_head")
git diff --name-only "$before_head" > ".fabro/tmp/${kind}-repair-after-files.txt"
git diff --stat "$before_head" > ".fabro/tmp/${kind}-repair-after-stat.txt" || true

printf 'Repair baseline (%s) captured at HEAD %s in %s\n' "$kind" "$before_head" "$before"
printf 'Repair after    (%s) captured at HEAD %s in %s\n' "$kind" "$(git rev-parse HEAD)" "$after"
printf 'Changed files after repair:\n%s\n' "${changed_files:-<none>}"

if cmp -s "$before" "$after"; then
  echo "${kind} repair produced no repository change since repair started." >&2
  echo "If no code/config/test changes were required, route to human input or make the repair prompt explicitly justify that case." >&2
  exit 1
fi

feature_changes=$(printf '%s\n' "$changed_files" | grep -E '\.feature$' || true)
if [ -n "$feature_changes" ]; then
  echo "Repair modified locked acceptance feature files:" >&2
  printf '%s\n' "$feature_changes" >&2
  exit 1
fi
