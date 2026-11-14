#!/usr/bin/env bash
# src/lib/validate-commit-message.sh
#
# Depends on gitflow_branch_is_exception, gitflow_branch_is_merge_branch,
# and gitflow_jira_keys_regex from lib/validate-branch-name.sh, and on
# GITFLOW_ENV_FILENAME/GITFLOW_ENV_SAMPLE_FILENAME from src/lib/config.sh.

# Anything shaped like "<KEY>-<number>:" at the start of a subject, whether
# or not KEY is configured. The colon keeps ordinary sentences such as
# "UTF-8 support added." from being mistaken for a ticket prefix.
GITFLOW_TICKET_PREFIX_REGEX='^([A-Z][A-Z0-9]*-[0-9]+):'

# gitflow_validate_sentence <text> [ticket]
# The description part of a subject: non-empty, starts with a capital
# letter, ends with a period. ticket (if the subject has one) only tailors
# the "missing description" message.
gitflow_validate_sentence() {
  local text="$1" ticket="${2:-}"

  if [[ -z "$text" ]]; then
    if [[ -n "$ticket" ]]; then
      echo "[gitflow] Commit message is missing a description after '${ticket}: '." >&2
    else
      echo "[gitflow] Commit message is empty." >&2
    fi
    return 1
  fi

  if [[ ! "$text" =~ ^[A-Z] ]]; then
    echo "[gitflow] Commit message description must start with a capital letter." >&2
    return 1
  fi

  if [[ "$text" != *. ]]; then
    echo "[gitflow] Commit message must end with a period." >&2
    return 1
  fi

  return 0
}

# gitflow_validate_prefixed_message <subject> <ticket>
# subject is already known to start with ticket; checks the ": " separator
# and then the sentence that follows it.
gitflow_validate_prefixed_message() {
  local subject="$1" ticket="$2"

  local after_ticket="${subject:${#ticket}}"
  if [[ "$after_ticket" != ": "* ]]; then
    echo "[gitflow] Commit message must have a colon and a space right after the ticket key, e.g. '${ticket}: Add login form.'." >&2
    return 1
  fi

  gitflow_validate_sentence "${after_ticket#": "}" "$ticket"
}

# gitflow_validate_commit_message <subject> <branch> <jira_keys_csv> <exceptions_csv> [mode]
# mode is the resolved GITFLOW_JIRA_KEY (default REQUIRED):
#   REQUIRED  "<branch>: Capitalized descriptive sentence." - the branch is
#             an exact KEY-number, and the ticket prefix must match it.
#   NONE      "Capitalized descriptive sentence." - no ticket prefix allowed.
#   OPTIONAL  on a KEY-number branch, same as REQUIRED; on any other branch
#             the prefix is optional, but if present its key must be one of
#             the configured ones.
# Each way the subject can fail is diagnosed with its own specific message.
# A merge/KEY-number/<target> branch has no single unambiguous ticket to
# prefix with, so it's exempt from the format check, same as an exception.
gitflow_validate_commit_message() {
  local subject="$1" branch="$2" jira_keys_csv="$3" exceptions_csv="$4" mode="${5:-REQUIRED}"

  if gitflow_branch_is_exception "$branch" "$exceptions_csv"; then
    return 0
  fi

  if gitflow_branch_is_merge_branch "$branch" "$jira_keys_csv"; then
    return 0
  fi

  if [[ "$mode" == "NONE" ]]; then
    if [[ "$subject" =~ $GITFLOW_TICKET_PREFIX_REGEX ]]; then
      echo "[gitflow] Commit message must not start with a ticket key ('${BASH_REMATCH[1]}'): GITFLOW_JIRA_KEY is NONE in ${GITFLOW_ENV_FILENAME}." >&2
      return 1
    fi
    gitflow_validate_sentence "$subject"
    return
  fi

  if [[ -z "$jira_keys_csv" ]]; then
    echo "[gitflow] GITFLOW_JIRA_KEYS is not set in ${GITFLOW_ENV_FILENAME} (the file may exist but be missing this key - see ${GITFLOW_ENV_SAMPLE_FILENAME})." >&2
    return 1
  fi

  local keys_pattern
  keys_pattern=$(gitflow_jira_keys_regex "$jira_keys_csv")

  if [[ "$branch" =~ ^(${keys_pattern})-[0-9]+$ ]]; then
    # The branch is a ticket: the subject must carry exactly that ticket.
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

    gitflow_validate_prefixed_message "$subject" "$branch"
    return
  fi

  if [[ "$mode" == "REQUIRED" ]]; then
    echo "[gitflow] Current branch '${branch}' does not match a configured Jira key, so its commit messages cannot be validated." >&2
    return 1
  fi

  # OPTIONAL on a branch that is not a ticket: the prefix is up to the author.
  if [[ "$subject" =~ ^(${keys_pattern})-[0-9]+ ]]; then
    gitflow_validate_prefixed_message "$subject" "${BASH_REMATCH[0]}"
    return
  fi

  if [[ "$subject" =~ $GITFLOW_TICKET_PREFIX_REGEX ]]; then
    echo "[gitflow] Commit message ticket key '${BASH_REMATCH[1]}' is not one of the configured Jira keys: ${jira_keys_csv}." >&2
    return 1
  fi

  gitflow_validate_sentence "$subject"
}
