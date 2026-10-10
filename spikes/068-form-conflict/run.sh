#!/usr/bin/env bash
# Run inside the repo's devenv shell after web test dependencies have compiled.
# No application startup, database, routes or network services used by this runner.
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
root=$(cd "$here/../.." && pwd)
export ELIXIR_ERL_OPTIONS="${ELIXIR_ERL_OPTIONS:-+fnu}"
elixir "$here/draft_test.exs"
elixir -pa "$root/web/_build/test/lib/*/ebin" "$here/warning_test.exs"
