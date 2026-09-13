#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd -P)
tmpdir=$(mktemp -d)
tmpdir=$(cd "$tmpdir" && pwd -P)
trap 'rm -rf "$tmpdir"' EXIT

source_root="$tmpdir/source-checkout"
foreign_root="$tmpdir/foreign-checkout"
tools_dir="$tmpdir/tools"
log_file="$tmpdir/invocations.log"
foreign_pg="$foreign_root/.devenv/postgres-socket"
source_pg="$source_root/.devenv/postgres-socket"

mkdir -p "$source_root/bin" "$source_root/web" "$source_root/.devenv/state/postgres"
mkdir -p "$foreign_root/bin" "$foreign_root/.devenv/state/postgres"
mkdir -p "$tools_dir"
cp "$repo_root/bin/dev" "$source_root/bin/dev"
chmod +x "$source_root/bin/dev"

cat > "$tools_dir/argc" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
if [ "${1:-}" != "--argc-eval" ]; then
  echo "unexpected argc invocation: $*" >&2
  exit 64
fi
case "${3:-}" in
  precommit)
    printf 'precommit\n'
    ;;
  *)
    echo "unexpected dev command for fake argc: ${3:-<missing>}" >&2
    exit 64
    ;;
esac
SH
chmod +x "$tools_dir/argc"

cat > "$tools_dir/devenv" <<SH
#!/usr/bin/env bash
set -euo pipefail
printf 'devenv cwd=%s args=%s inbound_DEVENV_ROOT=%s inbound_PGHOST=%s inbound_PGPORT=%s\n' \
  "\$PWD" "\$*" "\${DEVENV_ROOT:-<unset>}" "\${PGHOST:-<unset>}" "\${PGPORT:-<unset>}" >> "$log_file"
if [ "\${PGHOST:-}" = "$foreign_pg" ] || [ "\${DEVENV_ROOT:-}" = "$foreign_root" ]; then
  echo "foreign checkout context leaked into devenv re-entry" >&2
  exit 65
fi
while [ "\$#" -gt 0 ]; do
  case "\$1" in
    -O)
      shift 3
      ;;
    shell)
      shift
      if [ "\${1:-}" != "--" ]; then
        echo "fake devenv expected shell --, got: \${1:-<missing>}" >&2
        exit 64
      fi
      shift
      break
      ;;
    *)
      echo "fake devenv only supports shell, got: \$*" >&2
      exit 64
      ;;
  esac
done
export DEVENV_ROOT="\$PWD"
export DEVENV_STATE="\$PWD/.devenv/state"
export DEVENV_PROFILE="\$PWD/.devenv/profile"
export PGHOST="\$PWD/.devenv/postgres-socket"
export PGPORT="\${MEMBA_POSTGRES_PORT:-15432}"
export PGDATA="\$PWD/.devenv/state/postgres"
export MEMBA_DEVENV_SHELL=1
export PATH="\$PWD/bin:\$PATH"
exec "\$@"
SH
chmod +x "$tools_dir/devenv"

cat > "$source_root/bin/mix" <<SH
#!/usr/bin/env bash
set -euo pipefail
printf 'source_mix cwd=%s args=%s DEVENV_ROOT=%s PGHOST=%s PGPORT=%s\n' \
  "\$PWD" "\$*" "\${DEVENV_ROOT:-<unset>}" "\${PGHOST:-<unset>}" "\${PGPORT:-<unset>}" >> "$log_file"
if [ "\$PWD" != "$source_root/web" ]; then
  echo "source mix ran from wrong cwd: \$PWD" >&2
  exit 41
fi
if [ "\${DEVENV_ROOT:-}" != "$source_root" ]; then
  echo "source mix saw wrong DEVENV_ROOT: \${DEVENV_ROOT:-<unset>}" >&2
  exit 42
fi
if [ "\${PGHOST:-}" = "$foreign_pg" ]; then
  echo "source mix inherited foreign PGHOST" >&2
  exit 43
fi
if [ "\${1:-}" != "precommit" ]; then
  echo "source mix expected precommit, got: \$*" >&2
  exit 44
fi
SH
chmod +x "$source_root/bin/mix"

cat > "$foreign_root/bin/mix" <<SH
#!/usr/bin/env bash
set -euo pipefail
printf 'foreign_mix cwd=%s args=%s DEVENV_ROOT=%s PGHOST=%s PGPORT=%s\n' \
  "\$PWD" "\$*" "\${DEVENV_ROOT:-<unset>}" "\${PGHOST:-<unset>}" "\${PGPORT:-<unset>}" >> "$log_file"
exit 77
SH
chmod +x "$foreign_root/bin/mix"

assert_mismatched_context_uses_source_checkout() {
  if grep -q '^foreign_mix ' "$log_file"; then
    echo "expected mismatched checkout context to avoid foreign mix wrapper" >&2
    cat "$log_file" >&2
    exit 1
  fi
  if ! grep -q '^devenv ' "$log_file"; then
    echo "expected mismatched checkout context to re-enter devenv" >&2
    cat "$log_file" >&2
    exit 1
  fi
  if ! grep -q "^source_mix .*DEVENV_ROOT=$source_root .*PGHOST=$source_pg" "$log_file"; then
    echo "expected source mix to run with source checkout DEVENV_ROOT and PGHOST" >&2
    cat "$log_file" >&2
    exit 1
  fi
}

# A shell marker from another checkout must not allow that checkout's wrapper or
# Postgres environment to be used for this checkout's dev command.
env \
  PATH="$foreign_root/bin:$tools_dir:${PATH:-}" \
  MEMBA_DEVENV_SHELL=1 \
  DEVENV_ROOT="$foreign_root" \
  DEVENV_STATE="$foreign_root/.devenv/state" \
  PGHOST="$foreign_pg" \
  PGPORT=25432 \
  PGDATA="$foreign_root/.devenv/state/postgres" \
  MEMBA_QUALITY_GATE_LOCK_ROOT="$tmpdir/locks" \
  "$source_root/bin/dev" precommit

assert_mismatched_context_uses_source_checkout

# Relative invocation from outside the checkout must re-enter using the absolute
# script path; otherwise cd "$repo_root" makes "$0" point at
# source-checkout/source-checkout/bin/dev.
: > "$log_file"
(
  cd "$tmpdir"
  env \
    PATH="$foreign_root/bin:$tools_dir:${PATH:-}" \
    MEMBA_DEVENV_SHELL=1 \
    DEVENV_ROOT="$foreign_root" \
    DEVENV_STATE="$foreign_root/.devenv/state" \
    PGHOST="$foreign_pg" \
    PGPORT=25432 \
    PGDATA="$foreign_root/.devenv/state/postgres" \
    MEMBA_QUALITY_GATE_LOCK_ROOT="$tmpdir/locks" \
    source-checkout/bin/dev precommit
)

assert_mismatched_context_uses_source_checkout

# A nested dev command already inside this checkout's devenv should keep working
# without another devenv re-entry, even if PATH contains another checkout first.
: > "$log_file"
env \
  PATH="$foreign_root/bin:$tools_dir:${PATH:-}" \
  MEMBA_DEVENV_SHELL=1 \
  DEVENV_ROOT="$source_root" \
  DEVENV_STATE="$source_root/.devenv/state" \
  PGHOST="$source_pg" \
  PGPORT=15432 \
  PGDATA="$source_root/.devenv/state/postgres" \
  MEMBA_QUALITY_GATE_LOCK_ROOT="$tmpdir/locks" \
  "$source_root/bin/dev" precommit

if grep -q '^foreign_mix\|^devenv ' "$log_file"; then
  echo "expected same-checkout nested command not to use foreign mix or re-enter devenv" >&2
  cat "$log_file" >&2
  exit 1
fi
if ! grep -q "^source_mix .*DEVENV_ROOT=$source_root .*PGHOST=$source_pg" "$log_file"; then
  echo "expected same-checkout nested command to use source mix wrapper" >&2
  cat "$log_file" >&2
  exit 1
fi

printf 'dev checkout-boundary tests passed\n'
