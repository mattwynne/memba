#!/usr/bin/env bash
set -euo pipefail

expected_source_head="${1:-}"

if [ -z "$expected_source_head" ]; then
  echo "expected_source_head is required for iteration implementation runs." >&2
  echo "Pass the exact source commit with -I expected_source_head=\$(git rev-parse HEAD)." >&2
  exit 1
fi

if ! [[ "$expected_source_head" =~ ^[0-9a-fA-F]{40}$ ]]; then
  echo "expected_source_head must be an exact 40-character Git object ID: $expected_source_head" >&2
  exit 1
fi

if ! actual_source_head=$(git rev-parse HEAD 2>/dev/null); then
  echo "Could not read the source checkout HEAD." >&2
  exit 1
fi

printf 'Expected source HEAD: %s\n' "$expected_source_head"
printf 'Actual source HEAD:   %s\n' "$actual_source_head"
printf 'Source directory:     %s\n' "$PWD"

if [ "$actual_source_head" != "$expected_source_head" ]; then
  echo "Refusing to run iteration implementation from the wrong source checkout." >&2
  echo "Re-run Fabro from the intended clean checkout or pass its exact HEAD deliberately." >&2
  exit 1
fi

echo "Source checkout matches the expected implementation commit."
