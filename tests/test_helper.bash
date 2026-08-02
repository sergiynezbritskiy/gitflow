GITFLOW_TEST_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GITFLOW_LIB_DIR="${GITFLOW_TEST_ROOT}/src/lib"

load_gitflow_libs() {
  # shellcheck disable=SC1090
  source "${GITFLOW_LIB_DIR}/config.sh"
  # shellcheck disable=SC1090
  source "${GITFLOW_LIB_DIR}/git-utils.sh"
  # shellcheck disable=SC1090
  source "${GITFLOW_LIB_DIR}/validate-branch-name.sh"
  # shellcheck disable=SC1090
  source "${GITFLOW_LIB_DIR}/validate-user-email.sh"
  # shellcheck disable=SC1090
  source "${GITFLOW_LIB_DIR}/validate-commit-message.sh"
}
