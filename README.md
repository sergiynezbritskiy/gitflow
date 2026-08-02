# gitflow

Bash git hooks that enforce a Jira-based gitflow convention: branch names must match a configured Jira key (`ABC-123`), commit messages must be `ABC-123: Capitalized sentence.`, and commit authors must use an approved email domain.

## Installation

Each method below runs `bin/install.sh` for you automatically — it wires up the git hooks (`core.hooksPath`) and copies `samples/.env.gitflow.sample` into your repo root, no manual steps required. Once it's run, continue to [Configuration](#configuration) to activate the sample file.

### PHP projects

```
composer require --dev sergiynezbritskiy/gitflow
```

Then add to your `composer.json`:

```json
{
  "scripts": {
    "post-install-cmd": [
      "bash vendor/sergiynezbritskiy/gitflow/bin/install.sh"
    ],
    "post-update-cmd": [
      "bash vendor/sergiynezbritskiy/gitflow/bin/install.sh"
    ]
  }
}
```

### Node projects

```
npm install --save-dev gitflow-hooks
```

Hooks install automatically via `postinstall` — no extra config needed.

### Bash installation

```
bash bin/install.sh
# or
make install
```

To remove: `bash bin/uninstall.sh` (or `make uninstall`).

## Configuration

Copy `samples/.env.gitflow.sample` (done automatically by `install.sh`) to `.env.gitflow` at your repo root, fill in the values, and commit it:

```
GITFLOW_JIRA_KEYS=ABC,TTD
GITFLOW_USER_EMAIL_DOMAINS=example.com
GITFLOW_BRANCH_EXCEPTIONS=master,main,develop,staging,merge/*,tmp_*
```

| Variable                     | Purpose                                                                                                   |
|------------------------------|-----------------------------------------------------------------------------------------------------------|
| `GITFLOW_JIRA_KEYS`          | Comma-separated Jira project keys. Branches must be `KEY-123` for one of these, or `merge/KEY-123/<target>` (e.g. `merge/ABC-123/staging`, `merge/ABC-123/ABC-124`) for a merge-tracking branch. |
| `GITFLOW_USER_EMAIL_DOMAINS` | Comma-separated allowed email domains for commit authors.                                                 |
| `GITFLOW_BRANCH_EXCEPTIONS`  | Comma-separated exact names and/or glob patterns (`*`, `?`) exempt from branch-name/commit-message rules. |

## Contributing

Unit tests use [bats-core](https://github.com/bats-core/bats-core):

```
npm install
npm test
# or
make test
```

No Node on your machine? Run the same suite in the `node` container defined in `docker-compose.yml`:

```
make docker-test
# or
docker compose run --rm node install --ignore-scripts
docker compose run --rm node test
```

`--ignore-scripts` matters here: without it, `postinstall` runs `install.sh` against the mounted repo and writes the container's `/app` path into your real `.git/config`.

`make lint` runs [ShellCheck](https://www.shellcheck.net/) if it's installed.

### Layout

```
src/hooks/        pre-commit, commit-msg — thin wrappers around src/lib/
src/lib/          pure, testable validator functions + config/git helpers
bin/install.sh    sets core.hooksPath (idempotent)
bin/uninstall.sh  unsets it (only if it's ours)
samples/          .env.gitflow.sample, copied into the target repo by install.sh
tests/            bats unit tests + an integration test
docker-compose.yml  php/node containers, for machines without Composer or npm
```

## Design notes

**Why `.env.gitflow` instead of `.env`.** Jira keys, allowed email domains, and branch exceptions are project configuration, not a secret — every contributor needs the same values, so the file must be committed. A typical `.env` is usually gitignored (and often holds real secrets), so reusing that filename/convention would either get the config silently ignored or encourage committing something that shouldn't be. `.env.gitflow` avoids both problems and typically isn't caught by an existing `.env`/`.gitignore` pattern. If your project's `.gitignore` uses a broad pattern like `.env*`, add an exception:
```
.env*
!.env.gitflow
```

`.env.gitflow` is read from the git repo root at commit time — not sourced, only the three `GITFLOW_*` keys are ever parsed, so a malformed or malicious config file can't run arbitrary shell code. Installing over a project that already has an unrelated `.env`/`.env.gitflow` is safe: unknown keys are left untouched. If the `GITFLOW_*` keys aren't present yet, hooks **fail closed** — every commit is rejected with a message pointing at the missing key — rather than silently letting everything through.

**Why `core.hooksPath` instead of copying into `.git/hooks`.** Hooks stay in sync with the source and work the same whether this repo is used standalone or vendored into another project, since nothing needs re-copying after an update.

**Why Composer and npm behave differently.** Composer does not auto-run a dependency's scripts (a deliberate security restriction), so the composer path above only fires automatically when this repo itself is the Composer root project — vendoring it into another PHP project requires that one line in the consumer's own `composer.json`. npm/yarn/pnpm, by contrast, genuinely run a dependency's `postinstall` automatically, so the npm path needs no extra wiring.

**Merge commits** are always exempt from the commit-message check (detected via `MERGE_HEAD`, not the hook's `$2`, since `commit-msg` — unlike `prepare-commit-msg` — never receives a source argument). Branches on the exceptions list are exempt from both the branch-name and commit-message checks; the email check still always applies.

**`merge/KEY-123/<target>` branches** (e.g. `merge/ABC-123/staging`, `merge/ABC-123/ABC-124`) are accepted as valid branch names in their own right — the `KEY-123` segment must still be a real configured Jira key, unlike the looser `merge/*` glob exception. Commit messages on them are exempt from the `TICKET: Sentence.` format, since there's no single ticket a manual commit on such a branch could unambiguously be prefixed with.

**Auto-wiring future clones (optional).** `core.hooksPath` lives in `.git/config`, which isn't version controlled, so `install.sh` needs to run once per clone. To have every future `git clone`/`git init` on your machine pre-populate hooks automatically, point git at a template directory (a per-developer machine setting, not something this repo can do on your behalf):
```
git config --global init.templateDir '~/.git-templates'
mkdir -p ~/.git-templates/hooks
cp src/hooks/* ~/.git-templates/hooks/
```
