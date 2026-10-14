# Agent Guide

## Environment and Checks

- Run development commands through the flake, e.g. `nix develop -c ansible-lint`
  or `nix develop -c ansible-playbook --syntax-check local.yml`; do not install
  tooling outside Nix for repository work.
- `nix develop` provides Ansible, `ansible-lint`, `shellcheck`, `shfmt`,
  `oxfmt`, `typos`, and the YAML language server. GitHub Actions runs the same
  static checks; no privileged integration test runner is configured.
- Format Nix with `nix fmt`; Oxfmt uses `.oxfmtrc.json` (80-column width).

## Playbook Model

- `local.yml` is a localhost-only playbook. `./setup` is the provisioning
  entrypoint: it manages local vault/become password files, installs Galaxy
  collections, then runs the playbook.
- Bootstrap roles (`common`, `ssh`, `gpg`) always run. Passing Ansible tags
  replaces `default_roles`; the selected display role is still included.
- `host_os` is the lowercased Ansible distribution with spaces removed. Keep
  OS-specific role tasks in `tasks/void.yml` and `tasks/archlinux.yml`; role
  `tasks/main.yml` includes the matching file after the playbook validates the
  host OS.
- The only implemented display role is `xorg`.

## Secrets

- `.secrets/` holds credentials and encrypted material. Never inspect, print, or
  commit its contents. The passphrase and become-password files are
  intentionally gitignored.

## Containers

- `docker/void/docker-compose.yml` and `docker/archlinux/docker-compose.yml`
  mount the working tree read-write and hide `.secrets/` behind an empty tmpfs.
  They support static/package testing only; the Arch fixture does not boot
  systemd.
