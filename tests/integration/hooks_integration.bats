#!/usr/bin/env bats
# End-to-end: installs the real hooks into a scratch git repo via
# core.hooksPath and exercises them through actual `git commit` calls.

TOOL_ROOT="$(cd "$(dirname "${BATS_TEST_FILENAME}")/../.." && pwd)"

setup() {
  # npm sets INIT_CWD for every lifecycle script it runs (not just
  # install), and install.sh/uninstall.sh prefer INIT_CWD over $PWD to
  # resolve the target repo. Left set, a leaked INIT_CWD from an ambient
  # `npm test` would make every install.sh/uninstall.sh call below target
  # the real repo instead of the scratch $TEST_REPO created here.
  unset INIT_CWD

  TEST_REPO="$(mktemp -d)"
  git -C "$TEST_REPO" init -q -b main
  git -C "$TEST_REPO" config user.name "Test User"
  git -C "$TEST_REPO" config user.email "dev@example.com"

  (cd "$TEST_REPO" && bash "$TOOL_ROOT/bin/install.sh") >/dev/null

  # install.sh drops .env.gitflow.sample; simulate the customer renaming it
  # and filling in real values.
  cat > "$TEST_REPO/.env.gitflow" <<'EOF'
GITFLOW_JIRA_KEYS=ABC,TTD
GITFLOW_USER_EMAIL_DOMAINS=example.com
GITFLOW_BRANCH_EXCEPTIONS=master,main,tmp_*
EOF

  git -C "$TEST_REPO" commit -q --allow-empty -m "Init."
}

teardown() {
  rm -rf "$TEST_REPO"
}

@test "installs core.hooksPath pointing at the tool's hooks dir" {
  run git -C "$TEST_REPO" config --get core.hooksPath
  [ "$status" -eq 0 ]
  [ "$output" = "$TOOL_ROOT/src/hooks" ]
}

@test "install.sh copies .env.gitflow.sample into the repo root" {
  [ -f "$TEST_REPO/.env.gitflow.sample" ]
  diff -q "$TOOL_ROOT/samples/.env.gitflow.sample" "$TEST_REPO/.env.gitflow.sample"
}

@test "uninstall.sh removes core.hooksPath and both env files" {
  run bash -c "cd '$TEST_REPO' && bash '$TOOL_ROOT/bin/uninstall.sh'"
  [ "$status" -eq 0 ]

  run git -C "$TEST_REPO" config --get core.hooksPath
  [ "$status" -ne 0 ]
  [ ! -f "$TEST_REPO/.env.gitflow.sample" ]
  [ ! -f "$TEST_REPO/.env.gitflow" ]
}

@test "accepts a valid commit on a valid jira branch" {
  git -C "$TEST_REPO" checkout -qb ABC-123
  echo "content" > "$TEST_REPO/file.txt"
  git -C "$TEST_REPO" add file.txt
  run git -C "$TEST_REPO" commit -m "ABC-123: Add sample file."
  [ "$status" -eq 0 ]
}

@test "rejects a commit on a branch with no matching jira key" {
  git -C "$TEST_REPO" checkout -qb random-branch
  echo "content" > "$TEST_REPO/file.txt"
  git -C "$TEST_REPO" add file.txt
  run git -C "$TEST_REPO" commit -m "ABC-123: Add sample file."
  [ "$status" -ne 0 ]
}

@test "rejects a commit whose message does not match the branch pattern" {
  git -C "$TEST_REPO" checkout -qb ABC-123
  echo "content" > "$TEST_REPO/file.txt"
  git -C "$TEST_REPO" add file.txt
  run git -C "$TEST_REPO" commit -m "add sample file"
  [ "$status" -ne 0 ]
}

@test "rejects a commit message missing the colon after the ticket key" {
  git -C "$TEST_REPO" checkout -qb ABC-123
  echo "content" > "$TEST_REPO/file.txt"
  git -C "$TEST_REPO" add file.txt
  run git -C "$TEST_REPO" commit -m "ABC-123 Add sample file."
  [ "$status" -ne 0 ]
}

@test "rejects a commit from a disallowed email domain" {
  git -C "$TEST_REPO" checkout -qb ABC-123
  git -C "$TEST_REPO" config user.email "dev@evil.com"
  echo "content" > "$TEST_REPO/file.txt"
  git -C "$TEST_REPO" add file.txt
  run git -C "$TEST_REPO" commit -m "ABC-123: Add sample file."
  [ "$status" -ne 0 ]
}

@test "allows commits on an excepted branch without a jira prefix" {
  git -C "$TEST_REPO" checkout -qb tmp_scratch
  echo "content" > "$TEST_REPO/file.txt"
  git -C "$TEST_REPO" add file.txt
  run git -C "$TEST_REPO" commit -m "quick scratch commit"
  [ "$status" -eq 0 ]
}

@test "rejects commits when .env.gitflow exists but is missing the gitflow keys" {
  # Simulates a .env.gitflow that was copied from the sample but never
  # filled in (or a pre-existing file with unrelated keys).
  cat > "$TEST_REPO/.env.gitflow" <<'EOF'
DB_HOST=localhost
API_KEY=super-secret
EOF
  git -C "$TEST_REPO" checkout -qb ABC-123
  echo "content" > "$TEST_REPO/file.txt"
  git -C "$TEST_REPO" add file.txt
  run git -C "$TEST_REPO" commit -m "ABC-123: Add sample file."
  [ "$status" -ne 0 ]
  [[ "$output" == *"GITFLOW_JIRA_KEYS is not set"* ]]
}

@test "accepts a branch and any commit message on merge/KEY-123/target" {
  git -C "$TEST_REPO" checkout -qb merge/ABC-123/staging
  echo "content" > "$TEST_REPO/file.txt"
  git -C "$TEST_REPO" add file.txt
  run git -C "$TEST_REPO" commit -m "quick merge-tracking commit"
  [ "$status" -eq 0 ]
}

@test "accepts merge/KEY-123/KEY-124 as a valid branch name" {
  git -C "$TEST_REPO" checkout -qb merge/ABC-123/ABC-124
  echo "content" > "$TEST_REPO/file.txt"
  git -C "$TEST_REPO" add file.txt
  run git -C "$TEST_REPO" commit -m "quick merge-tracking commit"
  [ "$status" -eq 0 ]
}

@test "rejects merge/KEY-123 without a target segment" {
  git -C "$TEST_REPO" checkout -qb merge/ABC-123
  echo "content" > "$TEST_REPO/file.txt"
  git -C "$TEST_REPO" add file.txt
  run git -C "$TEST_REPO" commit -m "ABC-123: Add sample file."
  [ "$status" -ne 0 ]
}

@test "skips message validation for merge commits" {
  git -C "$TEST_REPO" checkout -qb ABC-123
  echo "a" > "$TEST_REPO/a.txt"
  git -C "$TEST_REPO" add a.txt
  git -C "$TEST_REPO" commit -q -m "ABC-123: Add a."

  git -C "$TEST_REPO" checkout -qb TTD-9 main
  echo "b" > "$TEST_REPO/b.txt"
  git -C "$TEST_REPO" add b.txt
  git -C "$TEST_REPO" commit -q -m "TTD-9: Add b."

  run git -C "$TEST_REPO" merge --no-ff --no-edit ABC-123
  [ "$status" -eq 0 ]
}
