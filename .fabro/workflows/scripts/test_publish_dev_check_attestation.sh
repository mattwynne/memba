#!/usr/bin/env bash
set -euo pipefail
script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
root=$(mktemp -d)
trap 'rm -rf "$root"' EXIT
git init -q --bare "$root/origin.git"
git init -q --initial-branch=main "$root/seed"
cd "$root/seed"
git config user.name Test
git config user.email test@example.com
printf 'base\n' > base
git add base
git commit -q -m base
git remote add origin "$root/origin.git"
git push -q origin main
for name in first second; do
  git clone -q "$root/origin.git" "$root/$name" 2>/dev/null || true
  cd "$root/$name"
  git config user.name Test
  git config user.email test@example.com
  git checkout -q -B main origin/main
  git commit -q --allow-empty -m "$name"
  sha=$(git rev-parse HEAD)
  git notes --ref=refs/notes/fabro-dev-check add -m "Validated-Commit: $sha" "$sha"
done
# Both sandboxes started without the notes ref. The second must retain the first
# proof even though it was created from an unrelated local notes history.
cd "$root/first"
"$script_dir/publish_dev_check_attestation.sh" "$(git rev-parse HEAD)"
cd "$root/second"
"$script_dir/publish_dev_check_attestation.sh" "$(git rev-parse HEAD)"
git fetch -q origin refs/notes/fabro-dev-check:refs/notes/verify
for name in first second; do
  sha=$(git -C "$root/$name" rev-parse HEAD)
  git notes --ref=refs/notes/verify show "$sha" | grep -Fxq "Validated-Commit: $sha"
done
# A stale sandbox containing a prior notes ref must also merge new remote notes.
git clone -q "$root/origin.git" "$root/third" 2>/dev/null || true
cd "$root/third"
git config user.name Test
git config user.email test@example.com
git checkout -q -B main origin/main
git fetch -q origin refs/notes/fabro-dev-check:refs/notes/fabro-dev-check
git commit -q --allow-empty -m third
third=$(git rev-parse HEAD)
git notes --ref=refs/notes/fabro-dev-check add -m "Validated-Commit: $third" "$third"
# No attestation is accepted for a different SHA.
if "$script_dir/publish_dev_check_attestation.sh" "$(git rev-parse HEAD^)" >"$root/invalid.out" 2>&1; then
  echo 'Expected missing proof to fail' >&2
  exit 1
fi
"$script_dir/publish_dev_check_attestation.sh" "$third"
git fetch -q origin +refs/notes/fabro-dev-check:refs/notes/verify
for name in first second; do
  sha=$(git -C "$root/$name" rev-parse HEAD)
  git notes --ref=refs/notes/verify show "$sha" | grep -Fxq "Validated-Commit: $sha"
done
git notes --ref=refs/notes/verify show "$third" | grep -Fxq "Validated-Commit: $third"

# Advance the remote *between* fetch/merge and push to exercise the retry.
git clone -q "$root/origin.git" "$root/racer" 2>/dev/null || true
cd "$root/racer"
git config user.name Test
git config user.email test@example.com
git checkout -q -B main origin/main
git fetch -q origin refs/notes/fabro-dev-check:refs/notes/fabro-dev-check
git commit -q --allow-empty -m racer
racer=$(git rev-parse HEAD)
git notes --ref=refs/notes/fabro-dev-check add -m "Validated-Commit: $racer" "$racer"
git clone -q "$root/origin.git" "$root/fourth" 2>/dev/null || true
cd "$root/fourth"
git config user.name Test
git config user.email test@example.com
git checkout -q -B main origin/main
git commit -q --allow-empty -m fourth
fourth=$(git rev-parse HEAD)
git notes --ref=refs/notes/fabro-dev-check add -m "Validated-Commit: $fourth" "$fourth"
real_git=$(command -v git)
mkdir "$root/wrapper"
cat > "$root/wrapper/git" <<'GIT'
#!/usr/bin/env bash
set -euo pipefail
if [ "${1:-}" = push ] && [ "${3:-}" = 'refs/notes/fabro-dev-check:refs/notes/fabro-dev-check' ] && [ ! -e "$RACE_MARKER" ]; then
  touch "$RACE_MARKER"
  (cd "$RACE_REPO" && "$REAL_GIT" push -q origin refs/notes/fabro-dev-check)
fi
exec "$REAL_GIT" "$@"
GIT
chmod +x "$root/wrapper/git"
REAL_GIT="$real_git" RACE_MARKER="$root/raced" RACE_REPO="$root/racer" PATH="$root/wrapper:$PATH" \
  "$script_dir/publish_dev_check_attestation.sh" "$fourth"
git fetch -q origin +refs/notes/fabro-dev-check:refs/notes/verify
for sha in "$third" "$racer" "$fourth"; do
  git notes --ref=refs/notes/verify show "$sha" | grep -Fxq "Validated-Commit: $sha"
done
[ -e "$root/raced" ]
echo 'attestation publication tests passed'
