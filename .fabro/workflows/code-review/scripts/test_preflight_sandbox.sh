#!/usr/bin/env bash
set -euo pipefail

script_path=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/preflight_sandbox.sh
workdir=$(mktemp -d)
trap 'rm -rf "$workdir"' EXIT

cd "$workdir"
git init -q --bare origin.git
git init -q --initial-branch=main repo
cd repo
git config user.name Test
git config user.email test@example.com
git remote add origin ../origin.git
mkdir -p bin
cat > bin/dev <<'DEV'
#!/usr/bin/env bash
set -euo pipefail
[ "${1:-}" = sandbox-check ] || exit 1
echo "sandbox ok"
DEV
chmod +x bin/dev
printf 'tree A\n' > implementation.txt
git add .
git commit -q -m 'review candidate A'
git push -q -u origin main
git -C "$workdir/origin.git" symbolic-ref HEAD refs/heads/main
candidate_a=$(git rev-parse HEAD)

# The detached review branch remains on A while main advances to B before
# preflight. This is the production race the provenance file must survive.
git switch -q -c code-review/candidate-a
other="$workdir/other"
git clone -q "$workdir/origin.git" "$other"
(
  cd "$other"
  git config user.name Other
  git config user.email other@example.com
  printf 'concurrent B\n' > concurrent.txt
  git add concurrent.txt
  git commit -q -m 'concurrent main B'
  git push -q origin main
)
main_b=$(git -C "$other" rev-parse HEAD)

# Model Fabro's read_plan checkpoint: a different commit with candidate A's tree.
git commit -q --allow-empty -m 'fabro(test): read_plan'
checkpoint_sha=$(git rev-parse HEAD)

bash "$script_path" "$candidate_a" >"$workdir/preflight.out" 2>"$workdir/preflight.err"
recorded_sha=$(cat .fabro/tmp/review-start-sha.txt)

[ "$recorded_sha" = "$candidate_a" ] || {
  echo "Expected launch candidate $candidate_a, got $recorded_sha" >&2
  exit 1
}
[ "$(cat .fabro/tmp/review-candidate-sha.txt)" = "$candidate_a" ]
[ "$recorded_sha" != "$checkpoint_sha" ]
[ "$recorded_sha" != "$main_b" ]
grep -Fq "Review candidate SHA (launch HEAD): $candidate_a" "$workdir/preflight.out"

# A retargeted sandbox must fail closed even when the requested commit exists.
rm -rf .fabro/tmp
printf 'unexpected mutation\n' > implementation.txt
git add implementation.txt
git commit -q -m retargeted
if bash "$script_path" "$candidate_a" >"$workdir/retarget.out" 2>"$workdir/retarget.err"; then
  echo 'Expected a sandbox whose tree differs from the launch candidate to fail.' >&2
  exit 1
fi
grep -Fq 'Review sandbox tree no longer matches the launch candidate' "$workdir/retarget.err"

echo "code-review preflight provenance tests passed"
