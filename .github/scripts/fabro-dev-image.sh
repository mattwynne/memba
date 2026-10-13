#!/usr/bin/env bash
set -euo pipefail

# A rerun is a new version, even when its source SHA and run ID are unchanged.
[[ "${GITHUB_SHA:-}" =~ ^[0-9a-f]{40}$ ]] || { echo 'Expected a full source SHA' >&2; exit 1; }
[[ "${GITHUB_RUN_ID:-}" =~ ^[1-9][0-9]*$ ]] || { echo 'Expected a GitHub run ID' >&2; exit 1; }
[[ "${GITHUB_RUN_ATTEMPT:-}" =~ ^[1-9][0-9]*$ ]] || { echo 'Expected a GitHub run attempt' >&2; exit 1; }
version="sha-${GITHUB_SHA}-run-${GITHUB_RUN_ID}-${GITHUB_RUN_ATTEMPT}"
[[ ${#version} -le 128 ]] || { echo 'Image version exceeds tag limit' >&2; exit 1; }

case "${1:-}" in
  version) printf '%s\n' "$version" ;;
  build|copy)
    # The same overrides must reach both evaluations: never copy the default
    # local image or stamp a different source/build identity at publication.
    exec devenv \
      --option containers.fabro-dev.version:string "$version" \
      --option env.MEMBA_FABRO_IMAGE_VERSION:string "$version" \
      --option env.MEMBA_FABRO_IMAGE_SOURCE:string "$GITHUB_SHA" \
      --option env.MEMBA_FABRO_IMAGE_BUILD:string "${GITHUB_RUN_ID}/${GITHUB_RUN_ATTEMPT}" \
      container "$1" fabro-dev
    ;;
  *) echo 'Usage: fabro-dev-image.sh version|build|copy' >&2; exit 1 ;;
esac
