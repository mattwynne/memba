#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
verifier="$script_dir/verify_source_head.sh"
workflow_dir=$(cd "$script_dir/.." && pwd)
workflow="$workflow_dir/workflow.fabro"
config="$workflow_dir/workflow.toml"
repo_root=$(cd "$workflow_dir/../../.." && pwd)

tmp=$(mktemp -d)
cleanup() {
  rm -rf "$tmp"
}
trap cleanup EXIT

git -C "$tmp" init -q
git -C "$tmp" config user.name Test
git -C "$tmp" config user.email test@example.com
printf 'test\n' > "$tmp/file.txt"
git -C "$tmp" add file.txt
git -C "$tmp" commit -qm initial
head_sha=$(git -C "$tmp" rev-parse HEAD)

(
  cd "$tmp"
  bash "$verifier" "$head_sha"
)

if (
  cd "$tmp"
  bash "$verifier" "0000000000000000000000000000000000000000"
) >"$tmp/wrong.out" 2>&1; then
  echo "Expected source verifier to reject the wrong HEAD" >&2
  exit 1
fi
grep -Fq "Expected source HEAD: 0000000000000000000000000000000000000000" "$tmp/wrong.out"
grep -Fq "Actual source HEAD:   $head_sha" "$tmp/wrong.out"

if (
  cd "$tmp"
  bash "$verifier" ""
) >"$tmp/missing.out" 2>&1; then
  echo "Expected source verifier to reject an omitted expected HEAD" >&2
  exit 1
fi
grep -Fq "expected_source_head is required" "$tmp/missing.out"

grep -Fq 'expected_source_head = ""' "$config"
grep -Fq 'verify_source_head [' "$workflow"
grep -Fq 'verify_source_head.sh' "$workflow"
grep -Fq 'start -> verify_source_head' "$workflow"
grep -Fq 'verify_source_head -> read_plan [condition="outcome=succeeded"]' "$workflow"
grep -Fq 'verify_source_head -> source_head_failed' "$workflow"
grep -Fq 'source_head_failed -> exit' "$workflow"
grep -Fq -- '-I expected_source_head="$base_sha"' "$repo_root/bin/dev"

printf 'source HEAD verification tests passed\n'
