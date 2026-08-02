#!/usr/bin/env bash
# src/lib/validate-commit-message.sh
#
# Depends on gitflow_branch_is_exception, gitflow_branch_is_merge_branch,
# and gitflow_jira_keys_regex from lib/validate-branch-name.sh, and on
# GITFLOW_ENV_FILENAME/GITFLOW_ENV_SAMPLE_FILENAME from src/lib/config.sh.

# gitflow_validate_commit_message <subject> <branch> <jira_keys_csv> <exceptions_csv>
# Requires: "<branch>: Capitalized descriptive sentence." (branch is already
# an exact KEY-number, so the ticket prefix must match it verbatim). Each
# way the subject can fail is diagnosed with its own specific message.
# A merge/KEY-number/<target> branch has no single unambiguous ticket to
# prefix with, so it's exempt from the format check, same as an exception.
gitflow_validate_commit_message() {
  local subject="$1" branch="$2" jira_keys_csv="$3" exceptions_csv="$4"

  if gitflow_branch_is_exception "$branch" "$exceptions_csv"; then
    return 0
  fi

  if gitflow_branch_is_merge_branch "$branch" "$jira_keys_csv"; then
    return 0
  fi

  if [[ -z "$jira_keys_csv" ]]; then
    echo "[gitflow] GITFLOW_JIRA_KEYS is not set in ${GITFLOW_ENV_FILENAME} (the file may exist but be missing this key - see ${GITFLOW_ENV_SAMPLE_FILENAME})." >&2
    return 1
  fi

  local keys_pattern
  keys_pattern=$(gitflow_jira_keys_regex "$jira_keys_csv")

  if [[ ! "$branch" =~ ^(${keys_pattern})-[0-9]+$ ]]; then
    echo "[gitflow] Current branch '${branch}' does not match a configured Jira key, so its commit messages cannot be validated." >&2
    return 1
  fi

  # Literal (non-glob) prefix compare via a quoted pattern, so branch names
  # can never be interpreted as a glob/regex here.
  if [[ "$subject" =~ ^(${keys_pattern})-[0-9]+ ]]; then
    local found_ticket="${BASH_REMATCH[0]}"
    if [[ "$found_ticket" != "$branch" ]]; then
      echo "[gitflow] Commit message ticket key '${found_ticket}' does not match the current branch '${branch}'." >&2
      return 1
    fi
  else
    echo "[gitflow] Commit message must start with the ticket key '${branch}'." >&2
    return 1
  fi

  local after_ticket="${subject:${#branch}}"
  if [[ "$after_ticket" != ": "* ]]; then
    echo "[gitflow] Commit message must have a colon and a space right after the ticket key, e.g. '${branch}: Add login form.'." >&2
    return 1
  fi

  local rest="${after_ticket#": "}"

  if [[ -z "$rest" ]]; then
    echo "[gitflow] Commit message is missing a description after '${branch}: '." >&2
    return 1
  fi

  if [[ ! "$rest" =~ ^[A-Z] ]]; then
    echo "[gitflow] Commit message description must start with a capital letter." >&2
    return 1
  fi

  if [[ "$rest" != *. ]]; then
    echo "[gitflow] Commit message must end with a period." >&2
    return 1
  fi

  return 0
}
