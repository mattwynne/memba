#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE' >&2
Usage: delegate-pi-gpt55.sh [--research|--write] [--keep-session] [--name NAME] [--cwd DIR] [--thinking LEVEL] [--] [PROMPT...]

Runs a one-shot Pi subagent using openai-codex/gpt-5.5.

Modes:
  --research      Read/search only: read,grep,find,ls. Default.
  --write         Full Pi tools; may edit files and run commands.

Input:
  Provide the prompt as arguments or on stdin, usually via a heredoc.
USAGE
}

mode="research"
keep_session=false
name="pi-gpt55-subagent"
cwd="."
thinking="high"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --research)
      mode="research"
      shift
      ;;
    --write)
      mode="write"
      shift
      ;;
    --keep-session)
      keep_session=true
      shift
      ;;
    --name)
      [[ $# -ge 2 ]] || { echo "Missing value for --name" >&2; usage; exit 2; }
      name="$2"
      shift 2
      ;;
    --cwd)
      [[ $# -ge 2 ]] || { echo "Missing value for --cwd" >&2; usage; exit 2; }
      cwd="$2"
      shift 2
      ;;
    --thinking)
      [[ $# -ge 2 ]] || { echo "Missing value for --thinking" >&2; usage; exit 2; }
      thinking="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    --)
      shift
      break
      ;;
    -* )
      echo "Unknown option: $1" >&2
      usage
      exit 2
      ;;
    *)
      break
      ;;
  esac
done

if [[ $# -gt 0 ]]; then
  prompt="$*"
else
  prompt="$(cat)"
fi

if [[ -z "${prompt//[[:space:]]/}" ]]; then
  echo "No prompt supplied" >&2
  usage
  exit 2
fi

args=(
  --provider openai-codex
  --model gpt-5.5
  --thinking "$thinking"
  --approve
  --name "$name"
)

if [[ "$keep_session" == false ]]; then
  args+=(--no-session)
fi

case "$mode" in
  research)
    args+=(--tools read,grep,find,ls)
    mode_instructions="You are a delegated Pi subagent running in research mode. Do not edit files or run shell commands. Inspect the repository with read/search tools only. Return concise findings with file references and any uncertainties."
    ;;
  write)
    mode_instructions="You are a delegated Pi subagent running in write mode. You may edit files only within the scope given in the prompt. Follow project instructions. Report changed paths, commands run, and checks/tests run."
    ;;
esac

full_prompt="$mode_instructions

Working directory: $(cd "$cwd" && pwd)

Delegated task:
$prompt"

cd "$cwd"
exec pi "${args[@]}" -p "$full_prompt"
