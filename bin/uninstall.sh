#!/usr/bin/env bash
# bin/uninstall.sh
#
# Removes core.hooksPath from the target repo, but only if it currently
# points at this tool's hooks directory (so we never clobber an unrelated
# hooksPath setting). Also removes the .env.gitflow(.sample) files that
# install.sh placed - if .env.gitflow was committed, it stays recoverable
# via git history/git checkout even after this deletes it from disk.
set -euo pipefail

_self_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_tool_root="$(cd "${_self_dir}/.." && pwd)"
hooks_dir="${_tool_root}/src/hooks"

# shellcheck source=src/lib/config.sh
source "${_tool_root}/src/lib/config.sh"

target_dir="${INIT_CWD:-$PWD}"

if ! repo_root=$(git -C "$target_dir" rev-parse --show-toplevel 2>/dev/null); then
  echo "[gitflow] '${target_dir}' is not inside a git repository; nothing to uninstall." >&2
  exit 0
fi

current=$(git -C "$repo_root" config --get core.hooksPath 2>/dev/null || true)

if [[ "$current" != "$hooks_dir" ]]; then
  echo "[gitflow] core.hooksPath is not set to this tool's hooks directory (current: '${current:-<unset>}'); leaving it untouched." >&2
  exit 0
fi

git -C "$repo_root" config --unset core.hooksPath
echo "[gitflow] Removed core.hooksPath from ${repo_root}/.git/config"

sample_src="${_tool_root}/samples/${GITFLOW_ENV_SAMPLE_FILENAME}"
sample_dst="${repo_root}/${GITFLOW_ENV_SAMPLE_FILENAME}"
env_file="${repo_root}/${GITFLOW_ENV_FILENAME}"

if [[ -f "$sample_dst" && "$sample_dst" != "$sample_src" ]]; then
  rm -f "$sample_dst"
  echo "[gitflow] Removed ${sample_dst}"
fi

if [[ -f "$env_file" ]]; then
  rm -f "$env_file"
  echo "[gitflow] Removed ${env_file} (still recoverable via git if it was committed)"
fi
