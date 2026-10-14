# ansible-dots

Local Ansible provisioning for stock Arch Linux with systemd and Void Linux with
runit.

## Support

Arch support targets a fresh, already booted Arch installation. It is not an
in-place Artix-to-Arch conversion tool. The Arch roles use `systemd_service` for
`sshd`, Nix, Cronie, Docker, Chrony, UFW, and the weekly `fstrim.timer`. Systemd
provides logind and journald; Elogind and Socklog are not installed.

The `system` and `drivers` roles support GRUB and `mkinitcpio` by default. Set
`manage_grub=false` for a systemd-boot, UKI, or other non-GRUB setup.

## Run

Clone this repository into the directory where managed repositories should live.
For example:

```text
~/Documents/github/ansible-dots
```

The playbook clones `dotfiles`, `nvim`, and other repositories beside the
`ansible-dots` checkout. Run the setup entrypoint as a regular user from a TTY:

```sh
./setup
```

On Arch, `setup` installs Nix with Pacman and enables `nix-daemon.service`. On
Void, it retains the native Runit daemon setup. It creates
`.secrets/.passphrase` and `.secrets/.become_password` only when absent,
enforces mode `0600` on every run, installs Galaxy collections, and runs
`local.yml`. Ansible is provided by this repository's Nix flake.

Secret material in `.secrets/` is required by several roles. Do not commit,
print, or mount it in test containers. The first successful run asks for a
reboot and records state under `~/.local/state/ansible_setup`.

## Roles

The playbook only targets the local host. `common`, `ssh`, and `gpg` always run;
the default role order is listed in `group_vars/all.yml`. `xorg` is the only
implemented display role and always runs with the selected roles. Unsupported
OSes, display roles, and role tags fail early.

Pass tags to run a focused set of target roles. Tags replace the default target
role list, while bootstrap roles and `xorg` still run:

```sh
nix develop -c ansible-playbook local.yml --tags cli
```

OS-specific task files use `void.yml` and `archlinux.yml`, matching Ansible's
normalized distribution name.

## Safety Defaults

Dotfile Stow adoption is disabled. Resolve conflicts manually, or explicitly
enable it after a backup:

```sh
nix develop -c ansible-playbook local.yml -e dotfiles_adopt=true
```

Replacing an existing `~/.config/nvim` directory also requires
`dotfiles_replace_existing_nvim=true`. Removing Waybar requires
`remove_waybar=true`. XDG secret-backed configuration remains non-overwriting by
default; set `xdg_config_force=true` only when the vault copy should replace the
local copy.

The firewall defaults preserve the prior LAN, Docker-network, torrent, and SSH
policy, but expose `ufw_lan_cidr`, `ufw_docker_cidr`, and `ufw_ssh_port` as
variables. The Docker group is root-equivalent access to the local daemon; set
`manage_docker_group=false` to opt out. Ventoy is no longer installed by default
because it needs an insecure Nix package; use `install_ventoy=true` to allow it.

`backup-notes` reads repository paths from `/etc/backup-notes.conf`, generated
from `backup_notes_repositories`. It serializes runs, reports missing or
diverged repositories, and only pushes; it never pulls or resolves conflicts.

## Checks

Run repository tooling through the flake. Galaxy collections are needed before
the Ansible checks:

```sh
nix develop -c ansible-galaxy collection install -r requirements/common.yml
nix develop -c ansible-playbook --syntax-check local.yml
nix develop -c ansible-lint
nix develop -c shellcheck setup docker/entrypoint.sh roles/services/tasks/files/common/backup-notes roles/sudo_scripts/tasks/files/common/usr/local/bin/system-cleanup roles/sudo_scripts/tasks/files/common/usr/local/bin/grub-update
nix develop -c shfmt -d setup docker/entrypoint.sh roles/services/tasks/files/common/backup-notes roles/sudo_scripts/tasks/files/common/usr/local/bin/system-cleanup roles/sudo_scripts/tasks/files/common/usr/local/bin/grub-update
nix develop -c oxfmt --check AGENTS.md README.md TODO.md .github/workflows/checks.yml group_vars/all.yml local.yml pre_tasks/whoami.yml requirements/common.yml requirements/arch.yml requirements/void.yml 'roles/**/*.yml' 'docker/**/*.yml'
nix develop -c typos
nix fmt -- --ci
```

GitHub Actions runs the same static checks. It intentionally does not run
provisioning or service activation.

## Containers

Manual static/package test environments are available for Void and Arch:

```sh
docker compose -f docker/void/docker-compose.yml run --rm ansible
docker compose -f docker/archlinux/docker-compose.yml run --rm ansible
docker compose -f docker/archlinux/docker-compose.yml run --rm ansible ansible-playbook --syntax-check local.yml
```

They bind-mount the checkout but hide `.secrets/` behind an empty tmpfs. The
entrypoint creates non-secret password-file fixtures only for static checks. The
Arch image does not boot systemd, so validate Arch service activation on a real
Arch VM or host before relying on it.
