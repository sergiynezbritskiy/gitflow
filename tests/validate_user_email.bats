#!/usr/bin/env bats

setup() {
  load 'test_helper'
  load_gitflow_libs
}

@test "accepts an email in the allowed domain" {
  run gitflow_validate_user_email "dev@example.com" "example.com"
  [ "$status" -eq 0 ]
}

@test "accepts an email matching one of several allowed domains" {
  run gitflow_validate_user_email "dev@other.org" "example.com,other.org"
  [ "$status" -eq 0 ]
}

@test "rejects an email in a disallowed domain" {
  run gitflow_validate_user_email "dev@evil.com" "example.com"
  [ "$status" -eq 1 ]
}

@test "is case insensitive on the domain" {
  run gitflow_validate_user_email "dev@Example.COM" "example.com"
  [ "$status" -eq 0 ]
}

@test "rejects a malformed email with no @" {
  run gitflow_validate_user_email "not-an-email" "example.com"
  [ "$status" -eq 1 ]
}

@test "rejects an empty email" {
  run gitflow_validate_user_email "" "example.com"
  [ "$status" -eq 1 ]
  [[ "$output" == *"Could not determine"* ]]
}

@test "fails with a clear error when GITFLOW_USER_EMAIL_DOMAINS is empty" {
  run gitflow_validate_user_email "dev@example.com" ""
  [ "$status" -eq 1 ]
  [[ "$output" == *"GITFLOW_USER_EMAIL_DOMAINS is not set"* ]]
}

@test "does not match a domain as a substring" {
  run gitflow_validate_user_email "dev@notexample.com" "example.com"
  [ "$status" -eq 1 ]
}
