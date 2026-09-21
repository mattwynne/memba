#!/usr/bin/env bash
set -euo pipefail

note_ref="refs/notes/fabro-dev-check"
commit_sha=$(git rev-parse HEAD)

if [ "$(git status --porcelain)" ]; then
  echo 'Refusing to attest a dirty publish candidate.' >&2
  git status --short >&2
  exit 1
fi

printf 'Running full ./bin/dev check for publish candidate %s...\n' "$commit_sha"
./bin/dev check

if [ "$(git rev-parse HEAD)" != "$commit_sha" ]; then
  echo 'Publish candidate changed while ./bin/dev check was running; refusing to attest it.' >&2
  exit 1
fi

if [ "$(git status --porcelain)" ]; then
  echo 'Publish candidate became dirty while ./bin/dev check was running; refusing to attest it.' >&2
  git status --short >&2
  exit 1
fi

note=$(mktemp)
trap 'rm -f "$note"' EXIT
{
  printf 'Fabro-Validation: ./bin/dev check passed\n'
  printf 'Validated-Commit: %s\n' "$commit_sha"
  printf 'Validated-At: %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
} > "$note"
git notes --ref="$note_ref" add -f -F "$note" "$commit_sha"

echo "Recorded successful full dev-check attestation for $commit_sha in $note_ref"
