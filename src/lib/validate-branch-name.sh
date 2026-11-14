#!/usr/bin/env bash
# src/lib/validate-branch-name.sh
#
# Depends on GITFLOW_ENV_FILENAME/GITFLOW_ENV_SAMPLE_FILENAME from
# src/lib/config.sh.

# gitflow_jira_keys_regex <jira_keys_csv>
# Builds an extended-regex alternation (e.g. "ABC|TTD") from a
# comma-separated Jira key list.
gitflow_jira_keys_regex() {
  printf '%s' "$1" | tr -d ' ' | tr ',' '|'
}

# gitflow_branch_is_exception <branch> <exceptions_csv>
# Matches an exact name or a glob pattern (merge/*, tmp_*, ...) from a
# comma-separated exceptions list.
gitflow_branch_is_exception() {
  local branch="$1" exceptions_csv="$2"
  [[ -z "$exceptions_csv" ]] && return 1

  local IFS=','
  local pattern
  for pattern in $exceptions_csv; do
    pattern="${pattern// /}"
    [[ -z "$pattern" ]] && continue
    # shellcheck disable=SC2053 # intentional glob match, not literal
    if [[ "$branch" == $pattern ]]; then
      return 0
    fi
  done
  return 1
}

# gitflow_branch_is_merge_branch <branch> <jira_keys_csv>
# Matches merge/<KEY-number>/<anything>, e.g. merge/ABC-123/staging or
# merge/ABC-123/ABC-124 - a merge-tracking branch for a real ticket.
gitflow_branch_is_merge_branch() {
  local branch="$1" jira_keys_csv="$2"
  [[ -z "$jira_keys_csv" ]] && return 1

  local keys_pattern
  keys_pattern=$(gitflow_jira_keys_regex "$jira_keys_csv")

  [[ "$branch" =~ ^merge/(${keys_pattern})-[0-9]+/.+$ ]]
}

# gitflow_validate_branch_name <branch> <jira_keys_csv> <exceptions_csv> [mode]
# Branch must be exactly KEY-<number> for one of the configured Jira keys,
# or merge/KEY-<number>/<anything>, unless it matches the exceptions list.
# mode is the resolved GITFLOW_JIRA_KEY (default REQUIRED); under NONE and
# OPTIONAL branch names are not checked at all.
gitflow_validate_branch_name() {
  local branch="$1" jira_keys_csv="$2" exceptions_csv="$3" mode="${4:-REQUIRED}"

  if [[ "$mode" != "REQUIRED" ]]; then
    return 0
  fi

  if gitflow_branch_is_exception "$branch" "$exceptions_csv"; then
    return 0
  fi

  if [[ -z "$jira_keys_csv" ]]; then
    echo "[gitflow] GITFLOW_JIRA_KEYS is not set in ${GITFLOW_ENV_FILENAME} (the file may exist but be missing this key - see ${GITFLOW_ENV_SAMPLE_FILENAME})." >&2
    return 1
  fi

  local keys_pattern
  keys_pattern=$(gitflow_jira_keys_regex "$jira_keys_csv")

  if [[ "$branch" =~ ^(${keys_pattern})-[0-9]+$ ]]; then
    return 0
  fi

  if gitflow_branch_is_merge_branch "$branch" "$jira_keys_csv"; then
    return 0
  fi

  local first_key="${jira_keys_csv%%,*}"
  first_key="${first_key// /}"
  echo "[gitflow] Branch name '${branch}' does not match a configured Jira key." >&2
  echo "[gitflow] Expected format: '${first_key}-123', or 'merge/${first_key}-123/<target>' for a merge branch, for one of: ${jira_keys_csv}." >&2
  echo "[gitflow] Or use one of the configured exceptions: ${exceptions_csv}." >&2
  return 1
}
