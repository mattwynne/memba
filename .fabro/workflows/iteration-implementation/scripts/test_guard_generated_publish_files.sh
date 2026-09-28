#!/usr/bin/env bash
set -euo pipefail

script=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/guard_generated_publish_files.py
fixture=$(mktemp -d)
trap 'rm -rf "$fixture"' EXIT
cd "$fixture"
git init -q --initial-branch=main
git config user.name Test
git config user.email test@example.com
printf 'baseline\n' > README.md
git add README.md
git commit -q -m baseline
base=$(git rev-parse HEAD)

python3 -B "$script" "$base" >/dev/null

assert_rejected() {
  local expected=$1
  if python3 -B "$script" "$base" > "$fixture/output" 2>&1; then
    echo "Expected bytecode guard to reject $expected" >&2
    exit 1
  fi
  grep -Fq -- "$expected" "$fixture/output" || {
    echo "Missing offending path $expected" >&2
    cat "$fixture/output" >&2
    exit 1
  }
}

mkdir -p scripts/__pycache__
printf 'cache' > scripts/__pycache__/helper.cpython-313.pyc
assert_rejected 'scripts/__pycache__/helper.cpython-313.pyc'
rm -rf scripts
printf 'cache' > test.pyc
assert_rejected 'test.pyc'
rm test.pyc

mkdir -p scripts/__pycache__
printf 'cache' > scripts/__pycache__/helper.cpython-313.pyc
git add scripts/__pycache__/helper.cpython-313.pyc
assert_rejected 'scripts/__pycache__/helper.cpython-313.pyc'
git commit -q -m 'checkpoint with generated cache'
assert_rejected 'scripts/__pycache__/helper.cpython-313.pyc'
git rm -q scripts/__pycache__/helper.cpython-313.pyc
git commit -q -m 'remove generated cache'
python3 -B "$script" "$base" >/dev/null

printf 'cache' > tracked.pyc
git add tracked.pyc
git commit -q -m 'tracked bytecode'
printf 'more cache' > tracked.pyc
assert_rejected 'tracked.pyc'

echo 'generated publish file guard tests passed'
