#!/usr/bin/env bash
# bin/install.sh
#
# Wires this tool's src/hooks/ directory into a target git repo via
# `git config core.hooksPath`. Idempotent - safe to re-run.
#
# Target repo resolution:
#   - Uses $INIT_CWD if set (npm sets this to the original invoking
#     directory even for a dependency's postinstall script, whose cwd is
#     otherwise node_modules/<pkg>), falling back to $PWD (correct for
#     manual `bash bin/install.sh` and for Composer scripts, which always
#     run with cwd at the consumer's composer.json directory).
set -euo pipefail

_self_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_tool_root="$(cd "${_self_dir}/.." && pwd)"
hooks_dir="${_tool_root}/src/hooks"

if [[ ! -d "$hooks_dir" ]]; then
  echo "[gitflow] hooks directory not found at ${hooks_dir}" >&2
  exit 1
fi

# shellcheck source=src/lib/config.sh
source "${_tool_root}/src/lib/config.sh"

target_dir="${INIT_CWD:-$PWD}"

if ! repo_root=$(git -C "$target_dir" rev-parse --show-toplevel 2>/dev/null); then
  echo "[gitflow] '${target_dir}' is not inside a git repository; skipping hook install." >&2
  exit 0
fi

chmod +x "${hooks_dir}"/* 2>/dev/null || true

git -C "$repo_root" config core.hooksPath "$hooks_dir"

echo "[gitflow] Installed git hooks: core.hooksPath -> ${hooks_dir}"
echo "[gitflow]   (for repo: ${repo_root})"

sample_src="${_tool_root}/samples/${GITFLOW_ENV_SAMPLE_FILENAME}"
sample_dst="${repo_root}/${GITFLOW_ENV_SAMPLE_FILENAME}"
env_file="${repo_root}/${GITFLOW_ENV_FILENAME}"

if [[ -f "$sample_src" && "$sample_src" != "$sample_dst" ]]; then
  cp "$sample_src" "$sample_dst"
  echo "[gitflow] Copied ${GITFLOW_ENV_SAMPLE_FILENAME} to ${repo_root}"
fi

if [[ ! -f "$env_file" ]]; then
  echo "[gitflow] Note: no ${GITFLOW_ENV_FILENAME} found at ${repo_root}." >&2
  echo "[gitflow]   Rename ${sample_dst} to ${GITFLOW_ENV_FILENAME}, configure it, and commit it (it's project config, not a secret)." >&2
fi

exit 0
