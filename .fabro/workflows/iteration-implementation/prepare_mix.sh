#!/usr/bin/env bash
set -euo pipefail

log() {
  printf '[prepare_mix] %s %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$*" >&2
}

cd /workspace/memba

log "starting prepare_mix in $(pwd)"
log "entering devenv shell"

devenv shell -- bash -lc '
  set -euo pipefail

  log() {
    printf "[prepare_mix] %s %s\n" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$*" >&2
  }

  run_step() {
    local label="$1"
    shift
    local started finished duration
    started=$(date +%s)
    log "START ${label}"
    "$@"
    finished=$(date +%s)
    duration=$((finished - started))
    log "DONE ${label} (${duration}s)"
  }

  log "inside devenv shell"

  if [ "$HOME" = "/env" ] || [ ! -d "$HOME" ] || [ ! -w "$HOME" ]; then
    log "HOME is not writable (${HOME}); using /tmp/home"
    export HOME=/tmp/home
  fi

  export MIX_HOME="${MIX_HOME:-$HOME/.mix}"
  export HEX_HOME="${HEX_HOME:-$HOME/.hex}"
  export HEX_CACERTS_PATH="${HEX_CACERTS_PATH:-${SSL_CERT_FILE:-${NIX_SSL_CERT_FILE:-}}}"

  log "HOME=${HOME} MIX_HOME=${MIX_HOME} HEX_HOME=${HEX_HOME}"
  run_step "create mix/hex home directories" mkdir -p "$HOME" "$MIX_HOME" "$HEX_HOME"

  cd web
  log "changed directory to $(pwd)"

  run_step "mix local.hex --force" mix local.hex --force
  run_step "mix local.rebar --force" mix local.rebar --force
  run_step "mix deps.get" mix deps.get
'

log "prepare_mix completed"
