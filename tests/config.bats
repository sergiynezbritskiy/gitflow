#!/usr/bin/env bats

setup() {
  load 'test_helper'
  load_gitflow_libs
  TEST_TMPDIR="$(mktemp -d)"
}

teardown() {
  rm -rf "$TEST_TMPDIR"
  unset GITFLOW_JIRA_KEYS GITFLOW_JIRA_KEY GITFLOW_USER_EMAIL_DOMAINS GITFLOW_BRANCH_EXCEPTIONS
}

@test "loads a well-formed .env.gitflow successfully" {
  cat > "$TEST_TMPDIR/.env.gitflow" <<'EOF'
GITFLOW_JIRA_KEYS=ABC,TTD
GITFLOW_USER_EMAIL_DOMAINS=example.com
GITFLOW_BRANCH_EXCEPTIONS=master,tmp_*
EOF
  run gitflow_load_config "$TEST_TMPDIR/.env.gitflow"
  [ "$status" -eq 0 ]
}

@test "exports the parsed variables into the environment" {
  cat > "$TEST_TMPDIR/.env.gitflow" <<'EOF'
GITFLOW_JIRA_KEYS=ABC,TTD
EOF
  gitflow_load_config "$TEST_TMPDIR/.env.gitflow"
  [ "$GITFLOW_JIRA_KEYS" = "ABC,TTD" ]
}

@test "ignores comment and blank lines" {
  cat > "$TEST_TMPDIR/.env.gitflow" <<'EOF'
# a comment
GITFLOW_JIRA_KEYS=ABC

GITFLOW_USER_EMAIL_DOMAINS=example.com
EOF
  gitflow_load_config "$TEST_TMPDIR/.env.gitflow"
  [ "$GITFLOW_JIRA_KEYS" = "ABC" ]
  [ "$GITFLOW_USER_EMAIL_DOMAINS" = "example.com" ]
}

@test "ignores unknown keys" {
  cat > "$TEST_TMPDIR/.env.gitflow" <<'EOF'
GITFLOW_JIRA_KEYS=ABC
SOME_OTHER_VAR=malicious
EOF
  gitflow_load_config "$TEST_TMPDIR/.env.gitflow"
  [ -z "${SOME_OTHER_VAR:-}" ]
}

@test "strips matching surrounding quotes from values" {
  cat > "$TEST_TMPDIR/.env.gitflow" <<'EOF'
GITFLOW_JIRA_KEYS="ABC,TTD"
EOF
  gitflow_load_config "$TEST_TMPDIR/.env.gitflow"
  [ "$GITFLOW_JIRA_KEYS" = "ABC,TTD" ]
}

@test "does not execute shell code embedded in .env.gitflow values" {
  cat > "$TEST_TMPDIR/.env.gitflow" <<'EOF'
GITFLOW_JIRA_KEYS=$(echo pwned)
EOF
  gitflow_load_config "$TEST_TMPDIR/.env.gitflow"
  [ "$GITFLOW_JIRA_KEYS" = '$(echo pwned)' ]
}

@test "fails with a clear error when the config file is missing" {
  run gitflow_load_config "$TEST_TMPDIR/does-not-exist.env.gitflow"
  [ "$status" -eq 1 ]
  [[ "$output" == *"Missing config file"* ]]
}

@test "succeeds but leaves GITFLOW_* unset when .env.gitflow exists but has no gitflow keys" {
  # Simulates installing gitflow over a project whose .env.gitflow was
  # copied from the sample but not filled in yet.
  cat > "$TEST_TMPDIR/.env.gitflow" <<'EOF'
DB_HOST=localhost
API_KEY=super-secret
EOF
  gitflow_load_config "$TEST_TMPDIR/.env.gitflow"
  [ -z "${GITFLOW_JIRA_KEYS:-}" ]
  [ -z "${GITFLOW_USER_EMAIL_DOMAINS:-}" ]
  [ -z "${GITFLOW_BRANCH_EXCEPTIONS:-}" ]
}

@test "gitflow_env_file_path resolves to <repo root>/.env.gitflow" {
  run gitflow_env_file_path
  [ "$status" -eq 0 ]
  [[ "$output" == */.env.gitflow ]]
}

@test "exports GITFLOW_JIRA_KEY without confusing it with GITFLOW_JIRA_KEYS" {
  cat > "$TEST_TMPDIR/.env.gitflow" <<'EOF'
GITFLOW_JIRA_KEYS=ABC,TTD
GITFLOW_JIRA_KEY=OPTIONAL
EOF
  gitflow_load_config "$TEST_TMPDIR/.env.gitflow"
  [ "$GITFLOW_JIRA_KEYS" = "ABC,TTD" ]
  [ "$GITFLOW_JIRA_KEY" = "OPTIONAL" ]
}

@test "jira key mode defaults to REQUIRED when unset" {
  run gitflow_resolve_jira_key_mode ""
  [ "$status" -eq 0 ]
  [ "$output" = "REQUIRED" ]
}

@test "jira key mode accepts NONE, REQUIRED and OPTIONAL" {
  local mode
  for mode in NONE REQUIRED OPTIONAL; do
    run gitflow_resolve_jira_key_mode "$mode"
    [ "$status" -eq 0 ]
    [ "$output" = "$mode" ]
  done
}

@test "jira key mode is case-insensitive and ignores surrounding spaces" {
  run gitflow_resolve_jira_key_mode " optional "
  [ "$status" -eq 0 ]
  [ "$output" = "OPTIONAL" ]
}

@test "jira key mode rejects an unknown value with a clear error" {
  run gitflow_resolve_jira_key_mode "SOMETIMES"
  [ "$status" -eq 1 ]
  [[ "$output" == *"Invalid GITFLOW_JIRA_KEY 'SOMETIMES'"* ]]
}
