#!/usr/bin/env bash
# src/lib/config.sh
#
# Safe config loader for gitflow hooks. Deliberately does NOT `source` the
# file - only known GITFLOW_* keys are parsed and exported, so a malformed
# or malicious config file cannot execute arbitrary shell code.
#
# Config lives in `.env.gitflow`, not `.env`: this is project configuration
# (Jira keys, allowed email domains) rather than a secret, so unlike a
# typical .env it is meant to be committed - and a distinct filename avoids
# collisions with a project's existing `.env`/`.gitignore` conventions.

GITFLOW_ENV_FILENAME=".env.gitflow"
GITFLOW_ENV_SAMPLE_FILENAME=".env.gitflow.sample"

GITFLOW_KNOWN_VARS=(
  GITFLOW_JIRA_KEYS
  GITFLOW_USER_EMAIL_DOMAINS
  GITFLOW_BRANCH_EXCEPTIONS
)

_gitflow_trim() {
  local s="$1"
  s="${s#"${s%%[![:space:]]*}"}"
  s="${s%"${s##*[![:space:]]}"}"
  printf '%s' "$s"
}

gitflow_env_file_path() {
  local repo_root
  repo_root=$(git rev-parse --show-toplevel 2>/dev/null) || return 1
  printf '%s' "${repo_root}/${GITFLOW_ENV_FILENAME}"
}

# gitflow_load_config [env_file]
# Parses KEY=VALUE pairs from env_file (default: <repo root>/.env.gitflow)
# and exports the ones matching GITFLOW_KNOWN_VARS. Unknown keys are ignored.
# shellcheck disable=SC2120 # env_file is intentionally optional
gitflow_load_config() {
  local env_file="${1:-}"

  if [[ -z "$env_file" ]]; then
    env_file=$(gitflow_env_file_path) || {
      echo "[gitflow] Not inside a git repository." >&2
      return 1
    }
  fi

  if [[ ! -f "$env_file" ]]; then
    echo "[gitflow] Missing config file: $env_file." >&2
    echo "[gitflow] Run bin/install.sh (it copies ${GITFLOW_ENV_SAMPLE_FILENAME} into the repo root), then rename the copy to ${GITFLOW_ENV_FILENAME}, configure it, and commit it." >&2
    return 1
  fi

  local line key value known
  while IFS= read -r line || [[ -n "$line" ]]; do
    line=$(_gitflow_trim "$line")

    [[ -z "$line" ]] && continue
    [[ "$line" == \#* ]] && continue
    [[ "$line" != *=* ]] && continue

    key="${line%%=*}"
    value="${line#*=}"
    key=$(_gitflow_trim "$key")
    value=$(_gitflow_trim "$value")

    if [[ "$value" == \"*\" && "$value" == *\" ]]; then
      value="${value#\"}"
      value="${value%\"}"
    elif [[ "$value" == \'*\' && "$value" == *\' ]]; then
      value="${value#\'}"
      value="${value%\'}"
    fi

    for known in "${GITFLOW_KNOWN_VARS[@]}"; do
      if [[ "$key" == "$known" ]]; then
        export "${key}=${value}"
      fi
    done
  done < "$env_file"

  return 0
}
