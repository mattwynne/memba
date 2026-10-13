#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../.."
helper="$PWD/.github/scripts/fabro-dev-image.sh"
export GITHUB_SHA=0123456789abcdef0123456789abcdef01234567
export GITHUB_RUN_ID=12345 GITHUB_RUN_ATTEMPT=1
first="$("$helper" version)"
test "$first" = "sha-$GITHUB_SHA-run-12345-1"
export GITHUB_RUN_ATTEMPT=2
test "$("$helper" version)" != "$first"
export GITHUB_RUN_ID=12346
test "$("$helper" version)" = "sha-$GITHUB_SHA-run-12346-2"
for variable in GITHUB_SHA GITHUB_RUN_ID GITHUB_RUN_ATTEMPT; do
  if env "$variable=invalid" "$helper" version >/dev/null 2>&1; then
    echo "Accepted invalid $variable" >&2
    exit 1
  fi
done

scratch="$(mktemp -d)"
trap 'rm -rf "$scratch"' EXIT
printf '#!/bin/bash\nprintf "%%s\\n" "$@"\n' > "$scratch/devenv"
chmod +x "$scratch/devenv"
for operation in build copy; do
  PATH="$scratch:$PATH" "$helper" "$operation" > "$scratch/$operation"
done
python3 - "$scratch" <<'PY'
import sys
from pathlib import Path
p = Path(sys.argv[1])
a = (p / 'build').read_text().splitlines()
b = (p / 'copy').read_text().splitlines()
assert a[:-2] == b[:-2], 'build and copy must use identical overrides'
assert a[-3:] == ['container', 'build', 'fabro-dev']
assert b[-3:] == ['container', 'copy', 'fabro-dev']
assert len(a) == 15
assert a[:3] == ['--option', 'containers.fabro-dev.version:string',
                 'sha-0123456789abcdef0123456789abcdef01234567-run-12346-2']
assert a[3:6] == ['--option', 'env.MEMBA_FABRO_IMAGE_VERSION:string', a[2]]
assert a[6:9] == ['--option', 'env.MEMBA_FABRO_IMAGE_SOURCE:string',
                 '0123456789abcdef0123456789abcdef01234567']
assert a[9:12] == ['--option', 'env.MEMBA_FABRO_IMAGE_BUILD:string', '12346/2']
w = Path('.github/workflows/fabro-dev-image.yml').read_text()
assert 'cancel-in-progress: false' in w
assert 'fabro-dev-image.sh build' in w and 'fabro-dev-image.sh copy' in w
assert ':latest' not in w
assert w.index('fabro-dev-image.sh copy') < w.index('skopeo inspect') < w.index('actions/upload-artifact@v4')
assert 'always()' not in w, 'failed jobs must not issue publication receipts'
PY
printf 'Fabro image publication contracts: OK\n'
