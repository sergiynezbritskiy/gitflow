#!/usr/bin/env bats

setup() {
  load 'test_helper'
  load_gitflow_libs
}

@test "accepts a branch matching a configured jira key" {
  run gitflow_validate_branch_name "ABC-123" "ABC,TTD" ""
  [ "$status" -eq 0 ]
}

@test "accepts a branch matching another configured jira key" {
  run gitflow_validate_branch_name "TTD-9" "ABC,TTD" ""
  [ "$status" -eq 0 ]
}

@test "rejects a branch with no matching jira key" {
  run gitflow_validate_branch_name "TEST" "ABC,TTD" ""
  [ "$status" -eq 1 ]
}

@test "rejects a branch with an unknown key prefix" {
  run gitflow_validate_branch_name "HELLO-123" "ABC,TTD" ""
  [ "$status" -eq 1 ]
}

@test "rejects a branch with a suffix after the ticket number" {
  run gitflow_validate_branch_name "ABC-123-add-login" "ABC,TTD" ""
  [ "$status" -eq 1 ]
}

@test "rejects a branch with a non-numeric ticket number" {
  run gitflow_validate_branch_name "ABC-abc" "ABC,TTD" ""
  [ "$status" -eq 1 ]
}

@test "is case sensitive on the jira key" {
  run gitflow_validate_branch_name "abc-123" "ABC,TTD" ""
  [ "$status" -eq 1 ]
}

@test "accepts an exact-match exception branch" {
  run gitflow_validate_branch_name "master" "ABC,TTD" "master,staging"
  [ "$status" -eq 0 ]
}

@test "accepts a glob-match exception branch (merge/*)" {
  run gitflow_validate_branch_name "merge/ABC-123" "ABC,TTD" "master,merge/*"
  [ "$status" -eq 0 ]
}

@test "accepts a glob-match exception branch (tmp_*)" {
  run gitflow_validate_branch_name "tmp_scratch" "ABC,TTD" "tmp_*"
  [ "$status" -eq 0 ]
}

@test "rejects a branch not covered by exceptions" {
  run gitflow_validate_branch_name "feature/foo" "ABC,TTD" "master,tmp_*"
  [ "$status" -eq 1 ]
}

@test "fails with a clear error when GITFLOW_JIRA_KEYS is empty and branch is not excepted" {
  run gitflow_validate_branch_name "ABC-123" "" ""
  [ "$status" -eq 1 ]
  [[ "$output" == *"GITFLOW_JIRA_KEYS is not set"* ]]
}

@test "handles exceptions list with surrounding spaces" {
  run gitflow_validate_branch_name "staging" "ABC,TTD" "master, staging , tmp_*"
  [ "$status" -eq 0 ]
}

@test "accepts a merge branch targeting a plain name (merge/KEY-123/staging)" {
  run gitflow_validate_branch_name "merge/ABC-123/staging" "ABC,TTD" ""
  [ "$status" -eq 0 ]
}

@test "accepts a merge branch targeting another ticket (merge/KEY-123/KEY-124)" {
  run gitflow_validate_branch_name "merge/ABC-123/ABC-124" "ABC,TTD" ""
  [ "$status" -eq 0 ]
}

@test "rejects a merge branch with an unconfigured jira key" {
  run gitflow_validate_branch_name "merge/RANDOM-999/staging" "ABC,TTD" ""
  [ "$status" -eq 1 ]
}

@test "rejects a merge branch missing the target segment" {
  run gitflow_validate_branch_name "merge/ABC-123" "ABC,TTD" ""
  [ "$status" -eq 1 ]
}

@test "rejects a merge branch with a malformed jira key" {
  run gitflow_validate_branch_name "merge/ABC123/staging" "ABC,TTD" ""
  [ "$status" -eq 1 ]
}
