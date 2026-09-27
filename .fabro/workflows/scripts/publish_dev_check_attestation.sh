#!/usr/bin/env bash
set -euo pipefail

# Publish a check result without discarding proofs written by another Fabro run.
# Run from the clean publish worktree after attest_dev_check.sh, before main push.
note_ref=refs/notes/fabro-dev-check
remote_ref="refs/notes/fabro-dev-check-remote-$$"
candidate=${1:?validated commit SHA required}
max_attempts=4

cleanup() { git update-ref -d "$remote_ref" 2>/dev/null || true; }
trap cleanup EXIT

if [ "$(git rev-parse HEAD)" != "$candidate" ]; then
  echo "Attestation candidate is not the publish worktree HEAD: $candidate" >&2
  exit 1
fi
verify_proof() {
  local proof
  proof=$(git notes --ref="$note_ref" show "$candidate") || {
    echo "Missing dev-check attestation for $candidate" >&2
    return 1
  }
  if ! grep -Fxq "Validated-Commit: $candidate" <<<"$proof"; then
    echo "Dev-check attestation does not match $candidate" >&2
    return 1
  fi
}
verify_proof

for ((attempt=1; attempt<=max_attempts; attempt++)); do
  # An absent remote notes ref is normal for the first attestation. Other
  # ls-remote errors (including authentication failures) must not be ignored.
  if git ls-remote --exit-code origin "$note_ref" > /dev/null; then
    git fetch -q origin "+$note_ref:$remote_ref"
    # The default manual strategy stops rather than choosing between two
    # conflicting proofs for the same commit. Never force-push a notes ref.
    git notes --ref="$note_ref" merge -s manual "$remote_ref"
    verify_proof
  else
    status=$?
    if [ "$status" -ne 2 ]; then
      echo "Unable to inspect remote dev-check attestations (exit $status)" >&2
      exit "$status"
    fi
  fi

  if git push origin "$note_ref:$note_ref"; then
    echo "Published dev-check attestation for $candidate"
    exit 0
  fi
  echo "Dev-check attestation ref moved during publication (attempt $attempt/$max_attempts)" >&2
done

echo "Could not publish dev-check attestation for $candidate after $max_attempts attempts; main was not pushed" >&2
exit 1
