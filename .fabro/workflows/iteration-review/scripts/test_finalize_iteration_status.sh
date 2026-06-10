#!/usr/bin/env bash
set -euo pipefail

script_path=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/finalize_iteration_status.sh
repo_dir=$(mktemp -d)
trap 'rm -rf "$repo_dir"' EXIT

cd "$repo_dir"
mkdir -p docs/kaizen
printf '# Problem: example\n' > docs/kaizen/example.md

output_path=$repo_dir/finalize-output.txt
bash "$script_path" docs/kaizen/example.md > "$output_path"

if ! grep -Fq 'not an iteration plan; skipping iteration status finalization' "$output_path"; then
  echo 'Expected non-iteration plan paths to skip finalization successfully.' >&2
  cat "$output_path" >&2
  exit 1
fi

if grep -Fq 'must end with /plan.md' "$output_path"; then
  echo 'Expected non-iteration plan paths not to fail with /plan.md requirement.' >&2
  cat "$output_path" >&2
  exit 1
fi

echo 'iteration-review finalization tests passed'
