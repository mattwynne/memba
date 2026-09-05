#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
verifier="$script_dir/verify_review_repair.sh"

tmp=$(mktemp -d)
cleanup() {
  rm -rf "$tmp"
}
trap cleanup EXIT

git -C "$tmp" init -q
git -C "$tmp" config user.name Test
git -C "$tmp" config user.email test@example.com
mkdir -p "$tmp/.fabro/tmp" "$tmp/docs" "$tmp/acceptance-tests/features"
printf 'original\n' > "$tmp/docs/example.md"
printf 'Feature: Original\n' > "$tmp/acceptance-tests/features/example.feature"
git -C "$tmp" add .
git -C "$tmp" commit -qm initial

snapshot() {
  git -C "$tmp" rev-parse HEAD > "$tmp/.fabro/tmp/review-repair-before-head.txt"
  git -C "$tmp" diff --binary HEAD > "$tmp/.fabro/tmp/review-repair-before.patch"
}

snapshot
printf 'staged repair\n' > "$tmp/docs/example.md"
git -C "$tmp" add docs/example.md
(
  cd "$tmp"
  bash "$verifier"
)
git -C "$tmp" reset --hard -q HEAD

snapshot
printf 'committed repair\n' > "$tmp/docs/example.md"
git -C "$tmp" add docs/example.md
git -C "$tmp" commit -qm repair
(
  cd "$tmp"
  bash "$verifier"
)
git -C "$tmp" reset --hard -q HEAD~1

snapshot
if (
  cd "$tmp"
  bash "$verifier"
) >"$tmp/no-change.out" 2>&1; then
  echo "Expected verifier to reject a no-op repair" >&2
  exit 1
fi
grep -Fq "review repair produced no repository change" "$tmp/no-change.out"

snapshot
printf 'Feature: Modified\n' > "$tmp/acceptance-tests/features/example.feature"
git -C "$tmp" add acceptance-tests/features/example.feature
if (
  cd "$tmp"
  bash "$verifier"
) >"$tmp/feature.out" 2>&1; then
  echo "Expected verifier to reject a staged feature change" >&2
  exit 1
fi
grep -Fq "Repair modified locked acceptance feature files" "$tmp/feature.out"

printf 'review repair verification tests passed\n'
