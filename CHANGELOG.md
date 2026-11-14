# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.0] - 2026-11-14

### Added

- `GITFLOW_JIRA_KEY` config option controlling whether commit messages carry a Jira ticket prefix:
  - `REQUIRED` (default) — `ABC-123: Some message.`; the branch must be named after the ticket and the prefix must match it. This is the behaviour of 1.0.x.
  - `OPTIONAL` — `Some message.` or `ABC-123: Some message.`; branch names are not checked, but on a branch named after a ticket the message must carry that same ticket.
  - `NONE` — `Some message.`; a ticket prefix is rejected and branch names are not checked. `GITFLOW_JIRA_KEYS` is not needed.
- An invalid `GITFLOW_JIRA_KEY` value rejects the commit with an error listing the allowed values.

### Changed

- The capital-letter and trailing-period rules now apply to the whole subject when it has no ticket prefix.

## [1.0.1] - 2026-08-02

No code changes; tagged on the same commit as 1.0.0.

## [1.0.0] - 2026-08-02

### Added

- `pre-commit` hook validating the branch name (`KEY-123` or `merge/KEY-123/<target>` for a configured Jira key) and the commit author's email domain.
- `commit-msg` hook validating the subject as `KEY-123: Capitalized sentence.` with the same ticket as the branch; merge commits are skipped.
- `.env.gitflow` configuration with `GITFLOW_JIRA_KEYS`, `GITFLOW_USER_EMAIL_DOMAINS` and `GITFLOW_BRANCH_EXCEPTIONS`, parsed without being sourced.
- `bin/install.sh` and `bin/uninstall.sh`, wired into Composer and npm installs, setting `core.hooksPath` and copying the sample config.
- bats test suite, ShellCheck lint and CI workflow.

[1.1.0]: https://github.com/sergiynezbritskiy/gitflow/compare/1.0.1...1.1.0
[1.0.1]: https://github.com/sergiynezbritskiy/gitflow/compare/1.0.0...1.0.1
[1.0.0]: https://github.com/sergiynezbritskiy/gitflow/releases/tag/1.0.0
