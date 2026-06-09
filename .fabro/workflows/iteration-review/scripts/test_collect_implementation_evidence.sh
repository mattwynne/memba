#!/usr/bin/env bash
set -euo pipefail

script_path=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/collect_implementation_evidence.sh
repo_dir=$(mktemp -d)
trap 'rm -rf "$repo_dir"' EXIT

assert_output_contains() {
  local expected=$1

  if ! grep -Fq -- "$expected" "$output_path"; then
    echo "Expected evidence output to contain: $expected" >&2
    echo '--- evidence output ---' >&2
    cat "$output_path" >&2
    exit 1
  fi
}

cd "$repo_dir"
git init --quiet
git config user.name 'Fabro Test'
git config user.email 'fabro-test@example.com'

printf 'initial\n' > README.md
git add README.md
git commit --quiet -m 'initial'
base_sha=$(git rev-parse HEAD)

mkdir -p .fabro/workflows/iteration-review docs/kaizen docs/misc
printf 'workflow evidence marker\n' > .fabro/workflows/iteration-review/workflow.fabro
printf 'kaizen evidence marker\n' > docs/kaizen/example.md
printf 'unexcerpted marker\n' > docs/misc/example.md
git add .
git commit --quiet -m 'change workflow and kaizen files'

output_path=$repo_dir/evidence-output.txt
bash "$script_path" "$base_sha" > "$output_path"

assert_output_contains '--- changed source/config/test/workflow/kaizen file excerpts ---'
assert_output_contains '=== .fabro/workflows/iteration-review/workflow.fabro ==='
assert_output_contains 'workflow evidence marker'
assert_output_contains '=== docs/kaizen/example.md ==='
assert_output_contains 'kaizen evidence marker'

if grep -Fq 'unexcerpted marker' "$output_path"; then
  echo 'Expected unrelated docs files to stay outside the excerpt filter.' >&2
  cat "$output_path" >&2
  exit 1
fi

if grep -Fq 'No changed files matched the excerpt filter.' "$output_path"; then
  echo 'Expected workflow/kaizen changes to match the excerpt filter.' >&2
  cat "$output_path" >&2
  exit 1
fi

echo 'iteration-review implementation evidence tests passed'
