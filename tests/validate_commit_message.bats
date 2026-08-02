#!/usr/bin/env bats

setup() {
  load 'test_helper'
  load_gitflow_libs
}

@test "accepts a well-formed commit message" {
  run gitflow_validate_commit_message "ABC-123: Add login form." "ABC-123" "ABC,TTD" ""
  [ "$status" -eq 0 ]
}

@test "rejects a message missing the colon after the ticket key" {
  run gitflow_validate_commit_message "ABC-123 Add login form." "ABC-123" "ABC,TTD" ""
  [ "$status" -eq 1 ]
}

@test "rejects a message not starting with a capital letter" {
  run gitflow_validate_commit_message "ABC-123: add login form." "ABC-123" "ABC,TTD" ""
  [ "$status" -eq 1 ]
}

@test "rejects a message not ending with a period" {
  run gitflow_validate_commit_message "ABC-123: Add login form" "ABC-123" "ABC,TTD" ""
  [ "$status" -eq 1 ]
}

@test "rejects a message whose ticket key does not match the branch" {
  run gitflow_validate_commit_message "TTD-9: Add login form." "ABC-123" "ABC,TTD" ""
  [ "$status" -eq 1 ]
}

@test "rejects a message missing the ticket key entirely" {
  run gitflow_validate_commit_message "Add login form." "ABC-123" "ABC,TTD" ""
  [ "$status" -eq 1 ]
}

@test "rejects a message that is only the ticket key" {
  run gitflow_validate_commit_message "ABC-123" "ABC-123" "ABC,TTD" ""
  [ "$status" -eq 1 ]
}

@test "rejects a message that is only the ticket key plus colon and space" {
  run gitflow_validate_commit_message "ABC-123: " "ABC-123" "ABC,TTD" ""
  [ "$status" -eq 1 ]
}

@test "skips validation entirely for exception branches" {
  run gitflow_validate_commit_message "anything goes" "master" "ABC,TTD" "master,tmp_*"
  [ "$status" -eq 0 ]
}

@test "rejects when the branch itself is not a valid jira branch and not an exception" {
  run gitflow_validate_commit_message "ABC-123: Add login form." "random-branch" "ABC,TTD" ""
  [ "$status" -eq 1 ]
}

@test "skips validation entirely for a merge branch (merge/KEY-123/staging)" {
  run gitflow_validate_commit_message "anything goes" "merge/ABC-123/staging" "ABC,TTD" ""
  [ "$status" -eq 0 ]
}

@test "skips validation entirely for a merge branch targeting another ticket" {
  run gitflow_validate_commit_message "Merge branch 'ABC-123' into ABC-124" "merge/ABC-123/ABC-124" "ABC,TTD" ""
  [ "$status" -eq 0 ]
}
