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

# --- GITFLOW_JIRA_KEY=NONE ---

@test "NONE: accepts a plain sentence" {
  run gitflow_validate_commit_message "Add login form." "feature/login" "" "" "NONE"
  [ "$status" -eq 0 ]
}

@test "NONE: accepts a plain sentence on a jira-looking branch" {
  run gitflow_validate_commit_message "Add login form." "ABC-123" "ABC,TTD" "" "NONE"
  [ "$status" -eq 0 ]
}

@test "NONE: rejects a message with a ticket prefix" {
  run gitflow_validate_commit_message "ABC-123: Add login form." "feature/login" "" "" "NONE"
  [ "$status" -eq 1 ]
  [[ "$output" == *"must not start with a ticket key"* ]]
}

@test "NONE: does not mistake a hyphenated word for a ticket prefix" {
  run gitflow_validate_commit_message "UTF-8 support added." "feature/login" "" "" "NONE"
  [ "$status" -eq 0 ]
}

@test "NONE: rejects a message not starting with a capital letter" {
  run gitflow_validate_commit_message "add login form." "feature/login" "" "" "NONE"
  [ "$status" -eq 1 ]
}

@test "NONE: rejects a message not ending with a period" {
  run gitflow_validate_commit_message "Add login form" "feature/login" "" "" "NONE"
  [ "$status" -eq 1 ]
}

@test "NONE: still skips validation for exception branches" {
  run gitflow_validate_commit_message "anything goes" "master" "" "master" "NONE"
  [ "$status" -eq 0 ]
}

# --- GITFLOW_JIRA_KEY=OPTIONAL ---

@test "OPTIONAL: jira branch accepts a message with the branch's ticket key" {
  run gitflow_validate_commit_message "ABC-123: Add login form." "ABC-123" "ABC,TTD" "" "OPTIONAL"
  [ "$status" -eq 0 ]
}

@test "OPTIONAL: jira branch rejects a message without the ticket key" {
  run gitflow_validate_commit_message "Add login form." "ABC-123" "ABC,TTD" "" "OPTIONAL"
  [ "$status" -eq 1 ]
  [[ "$output" == *"must start with the ticket key 'ABC-123'"* ]]
}

@test "OPTIONAL: jira branch rejects a message with a different ticket key" {
  run gitflow_validate_commit_message "ABC-124: Add login form." "ABC-123" "ABC,TTD" "" "OPTIONAL"
  [ "$status" -eq 1 ]
  [[ "$output" == *"does not match the current branch"* ]]
}

@test "OPTIONAL: non-jira branch accepts a plain sentence" {
  run gitflow_validate_commit_message "Add login form." "feature/login" "ABC,TTD" "" "OPTIONAL"
  [ "$status" -eq 0 ]
}

@test "OPTIONAL: non-jira branch accepts a message with a configured ticket key" {
  run gitflow_validate_commit_message "TTD-9: Add login form." "feature/login" "ABC,TTD" "" "OPTIONAL"
  [ "$status" -eq 0 ]
}

@test "OPTIONAL: non-jira branch rejects an unconfigured ticket key" {
  run gitflow_validate_commit_message "XYZ-1: Add login form." "feature/login" "ABC,TTD" "" "OPTIONAL"
  [ "$status" -eq 1 ]
  [[ "$output" == *"not one of the configured Jira keys"* ]]
}

@test "OPTIONAL: non-jira branch rejects a ticket key without the colon" {
  run gitflow_validate_commit_message "ABC-123 Add login form." "feature/login" "ABC,TTD" "" "OPTIONAL"
  [ "$status" -eq 1 ]
}

@test "OPTIONAL: non-jira branch still enforces the sentence rules" {
  run gitflow_validate_commit_message "add login form" "feature/login" "ABC,TTD" "" "OPTIONAL"
  [ "$status" -eq 1 ]
  run gitflow_validate_commit_message "ABC-123: add login form." "feature/login" "ABC,TTD" "" "OPTIONAL"
  [ "$status" -eq 1 ]
}

@test "OPTIONAL: fails with a clear error when GITFLOW_JIRA_KEYS is empty" {
  run gitflow_validate_commit_message "Add login form." "feature/login" "" "" "OPTIONAL"
  [ "$status" -eq 1 ]
  [[ "$output" == *"GITFLOW_JIRA_KEYS is not set"* ]]
}
