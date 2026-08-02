#!/usr/bin/env bash
# src/lib/validate-user-email.sh
#
# Depends on GITFLOW_ENV_FILENAME/GITFLOW_ENV_SAMPLE_FILENAME from
# src/lib/config.sh.

# gitflow_validate_user_email <email> <domains_csv>
gitflow_validate_user_email() {
  local email="$1" domains_csv="$2"

  if [[ -z "$email" ]]; then
    echo "[gitflow] Could not determine the committer's email (git user.email not set)." >&2
    return 1
  fi

  if [[ -z "$domains_csv" ]]; then
    echo "[gitflow] GITFLOW_USER_EMAIL_DOMAINS is not set in ${GITFLOW_ENV_FILENAME} (the file may exist but be missing this key - see ${GITFLOW_ENV_SAMPLE_FILENAME})." >&2
    return 1
  fi

  if [[ "$email" != *@* ]]; then
    echo "[gitflow] Commit author email '${email}' is not a valid email address." >&2
    return 1
  fi

  local email_domain="${email##*@}"
  email_domain="${email_domain,,}"

  local IFS=','
  local domain
  for domain in $domains_csv; do
    domain="${domain// /}"
    domain="${domain,,}"
    [[ -z "$domain" ]] && continue
    if [[ "$email_domain" == "$domain" ]]; then
      return 0
    fi
  done

  echo "[gitflow] Commit author email '${email}' is not in an allowed domain. Allowed: ${domains_csv} (see GITFLOW_USER_EMAIL_DOMAINS)." >&2
  return 1
}
