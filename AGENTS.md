# Agent Guide

## Environment and Checks

- Run development commands through the flake, e.g. `nix develop -c ansible-lint` or `nix develop -c ansible-playbook --syntax-check local.yml`; do not install tooling outside Nix for repository work.
- `nix develop` provides Ansible, `ansible-lint`, `shellcheck`, `shfmt`, `oxfmt`, `typos`, and the YAML language server. No CI or test runner is configured.
- Format Nix with `nix fmt`; Oxfmt uses `.oxfmtrc.json` (80-column width).

## Playbook Model

- `local.yml` is a localhost-only playbook. `./setup` is the provisioning entrypoint: it manages local vault/become password files, installs Galaxy collections, then runs the playbook.
- Bootstrap roles (`common`, `ssh`, `gpg`) always run. Passing Ansible tags replaces `default_roles`; the selected display role is still included.
- `host_os` is the lowercased Ansible distribution with spaces removed. Keep OS-specific role tasks in `tasks/void.yml` and `tasks/artixlinux.yml`; role `tasks/main.yml` conditionally includes the matching file.
- The only implemented display role is `xorg`.

## Secrets

- `.secrets/` holds credentials and encrypted material. Never inspect, print, or commit its contents. The passphrase and become-password files are intentionally gitignored.

## Containers

- `docker/void/docker-compose.yml` and `docker/artixlinux/docker-compose.yml` mount the working tree read-write and `.secrets/` read-only for manual target-environment testing.
