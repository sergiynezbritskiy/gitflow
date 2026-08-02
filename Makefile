BATS := $(shell [ -x node_modules/.bin/bats ] && echo node_modules/.bin/bats || echo bats)

.PHONY: install uninstall test lint docker-test

install:
	bash bin/install.sh

uninstall:
	bash bin/uninstall.sh

test:
	$(BATS) tests/ -r

# --ignore-scripts: install.sh's postinstall would otherwise write the
# container's /app path into this repo's real .git/config.
docker-test:
	docker compose run --rm node install --ignore-scripts
	docker compose run --rm node test

lint:
	@if command -v shellcheck >/dev/null 2>&1; then \
		shellcheck src/hooks/pre-commit src/hooks/commit-msg src/lib/*.sh bin/install.sh bin/uninstall.sh; \
	else \
		echo "shellcheck not installed; skipping lint" >&2; \
	fi
