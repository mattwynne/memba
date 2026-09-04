#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)
# shellcheck source=git_identity.sh
source "$repo_root/.fabro/workflows/scripts/git_identity.sh"

workdir=$(mktemp -d)
trap 'rm -rf "$workdir"' EXIT

cd "$workdir"
git init -q --initial-branch=main repo
cd repo
git config user.name Test
git config user.email test@example.com

printf 'example\n' > example.txt
git add example.txt
fabro_git_commit -m 'example commit' >/tmp/fabro-git-identity-commit.out

identity=$(git log -1 --format='%an <%ae>|%cn <%ce>')
if [ "$identity" != 'Fabro <noreply@fabro.sh>|Fabro <noreply@fabro.sh>' ]; then
  echo 'Expected Fabro helper to commit with approved non-GitHub-user email.' >&2
  echo "$identity" >&2
  exit 1
fi

if [ "$(git config --local user.name)" != 'Test' ] || [ "$(git config --local user.email)" != 'test@example.com' ]; then
  echo 'Expected Fabro helper not to mutate repo-local git identity.' >&2
  git config --local --get-regexp '^user\.' >&2
  exit 1
fi

printf 'tree example\n' > tree-example.txt
git add tree-example.txt
tree_sha=$(git write-tree)
tree_commit=$(fabro_git_commit_tree "$tree_sha" -p HEAD -m 'tree commit')
tree_identity=$(git show -s --format='%an <%ae>|%cn <%ce>' "$tree_commit")
if [ "$tree_identity" != 'Fabro <noreply@fabro.sh>|Fabro <noreply@fabro.sh>' ]; then
  echo 'Expected Fabro commit-tree helper to commit with approved non-GitHub-user email.' >&2
  echo "$tree_identity" >&2
  exit 1
fi

if [ "$(git config --local user.name)" != 'Test' ] || [ "$(git config --local user.email)" != 'test@example.com' ]; then
  echo 'Expected Fabro commit-tree helper not to mutate repo-local git identity.' >&2
  git config --local --get-regexp '^user\.' >&2
  exit 1
fi

if grep -R --line-number --fixed-strings 'fabro@users.noreply.github.com' "$repo_root/.fabro/workflows" | grep -v '/test_git_identity.sh:'; then
  echo 'Found forbidden GitHub user noreply address in Fabro workflow files.' >&2
  exit 1
fi

echo 'fabro git identity tests passed'
