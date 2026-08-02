#!/usr/bin/env bash
# src/lib/git-utils.sh
#
# Small helpers for reading the git state relevant to gitflow validation.

gitflow_current_branch() {
  # symbolic-ref (unlike rev-parse --abbrev-ref) works on an unborn branch,
  # i.e. before the repo's very first commit exists.
  git symbolic-ref --short HEAD 2>/dev/null
}

# Resolves the email that will actually be recorded as the commit's author,
# honoring user.email, includeIf conditional config, and GIT_AUTHOR_EMAIL
# overrides - unlike a plain `git config user.email` read.
gitflow_current_author_email() {
  local ident
  ident=$(git var GIT_AUTHOR_IDENT 2>/dev/null) || return 1
  if [[ "$ident" =~ \<([^\>]+)\> ]]; then
    printf '%s' "${BASH_REMATCH[1]}"
    return 0
  fi
  return 1
}

# True while a `git merge` is in progress (MERGE_HEAD exists), which covers
# both a clean auto-merge commit and a conflict resolved by hand. Squash
# merges (git merge --squash) do NOT set MERGE_HEAD and are intentionally
# still validated like a normal commit.
gitflow_is_merge_in_progress() {
  git rev-parse -q --verify MERGE_HEAD >/dev/null 2>&1
}
