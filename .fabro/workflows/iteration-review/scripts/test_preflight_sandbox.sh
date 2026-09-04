#!/usr/bin/env bash
set -euo pipefail

script_path=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/preflight_sandbox.sh
workdir=$(mktemp -d)
trap 'rm -rf "$workdir"' EXIT

if [ ! -f "$script_path" ]; then
  echo "Expected preflight script to exist: $script_path" >&2
  exit 1
fi

cd "$workdir"
git init -q --bare origin.git
git init -q repo
cd repo
git config user.name Test
git config user.email test@example.com
git remote add origin ../origin.git
git checkout -q -b main
mkdir -p bin
cat > bin/dev <<'DEV'
#!/usr/bin/env bash
set -euo pipefail
if [ "${1:-}" != "sandbox-check" ]; then
  echo "unexpected dev command: $*" >&2
  exit 1
fi
echo "sandbox ok"
DEV
chmod +x bin/dev
printf 'published implementation\n' > implementation.txt
git add .
git commit -q -m 'iteration 001: published implementation'
git push -q -u origin main
origin_main_sha=$(git rev-parse HEAD)

# Fabro checkpoints after read_plan before preflight; preflight must not use this
# automatic checkpoint as the review polish squash base.
git commit -q --allow-empty -m 'fabro(test): read_plan'
checkpoint_sha=$(git rev-parse HEAD)

bash "$script_path" >/tmp/review-preflight.out 2>/tmp/review-preflight.err
recorded_sha=$(cat .fabro/tmp/review-start-sha.txt)

if [ "$recorded_sha" != "$origin_main_sha" ]; then
  echo "Expected review start SHA to be fetched origin/main $origin_main_sha, got $recorded_sha" >&2
  cat /tmp/review-preflight.out >&2 || true
  cat /tmp/review-preflight.err >&2 || true
  exit 1
fi

if [ "$recorded_sha" = "$checkpoint_sha" ]; then
  echo "Review start SHA incorrectly captured checkpointed HEAD $checkpoint_sha" >&2
  exit 1
fi

if ! grep -Fq "Review start SHA (origin/main): $origin_main_sha" /tmp/review-preflight.out; then
  echo "Expected preflight output to identify origin/main review start SHA" >&2
  cat /tmp/review-preflight.out >&2 || true
  exit 1
fi

echo "iteration-review preflight sandbox tests passed"
