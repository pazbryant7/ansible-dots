#!/usr/bin/env sh

fail() {
  printf 'entrypoint: %s\n' "$1" >&2
  exit 1
}

main() {
  secrets_dir="${ANSIBLE_SECRETS_DIR:-/ansible/.secrets}"

  [ "$#" -gt 0 ] || fail "no command supplied"
  mkdir -p "$secrets_dir" || fail "could not create $secrets_dir"
  chmod 700 "$secrets_dir" || fail "could not secure $secrets_dir"

  # Use fixture values so static checks never need real secrets.
  printf '%s\n' 'container-test-only' >"$secrets_dir/.passphrase" ||
    fail "could not write vault password fixture"
  printf '%s\n' 'container-test-only' >"$secrets_dir/.become_password" ||
    fail "could not write become password fixture"
  chmod 600 "$secrets_dir/.passphrase" "$secrets_dir/.become_password" ||
    fail "could not secure password fixtures"

  exec "$@" || fail "could not execute $1"
}

main "$@"
