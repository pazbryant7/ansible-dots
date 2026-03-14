# ansible-dots

Ansible playbook to automate my Arch Linux workstation setup from a fresh
install.

## Usage

### On a real machine

Run the bootstrap script. It installs `git`, clones this repository, and hands
off to the `setup` script inside it.

```sh
curl -fsSL https://raw.githubusercontent.com/pazbryant7/ansible-dots/main/bootstrap | sh
```

The `setup` script will then prompt you for:

- **Sudo password** — used by Ansible `--become` to run privileged tasks
- **Vault passphrase** — used to decrypt your ansible-vault secrets
- **Shell** — `zsh` or `fish`
- **Compositor** — `xorg` or `wayland`

After the first run, reboot. Run `setup` again directly to complete
post-installation tasks (media sync, custom scripts):

```sh
~/ansible-dots/setup
```

---

### Testing with Docker

Simulates a fresh Arch Linux install: no repo, no secrets, no Ansible
pre-installed.

```sh
docker build -f Dockerfile.archlinux -t ansible-dots-test .
docker run -it --name ansible-dots-test ansible-dots-test
```

Inside the container, run the same bootstrap as a real machine:

```sh
curl -fsSL https://raw.githubusercontent.com/pazbryant7/ansible-dots/main/bootstrap | sh
```

When prompted for passwords, use dummy values. Vault-encrypted secrets will fail
to decrypt but the rest of the playbook structure can still be verified.

Cleanup:

```sh
docker rm -f ansible-dots-test
docker rmi ansible-dots-test
```

---

## Structure

```
.
├── ansible.cfg
├── bootstrap                # Step 1 — pipe into sh via curl on a fresh machine
├── setup                    # Step 2 — run directly after bootstrap
├── group_vars/
│   └── all.yml              # Role groups: bootstrap, default, shell, compositor
├── local.yml                # Main playbook
├── pre_tasks/
│   └── whoami.yml           # Detects current user and OS
├── requirements/
│   └── arch.yml             # Ansible Galaxy collections for Arch
└── roles/                   # One directory per role
```

## Roles

| Role              | Description                                                  |
| ----------------- | ------------------------------------------------------------ |
| `common`          | Base system packages and OS setup. Always runs first.        |
| `ssh`             | SSH key and config setup. Always runs second.                |
| `cli`             | CLI tools and utilities. Depends on `common`.                |
| `dotfiles`        | Symlinks config files from the dotfiles repo.                |
| `zsh`             | Zsh shell and plugins. Mutually exclusive with `fish`.       |
| `fish`            | Fish shell and plugins. Mutually exclusive with `zsh`.       |
| `xorg`            | X11 display server setup. Mutually exclusive with `wayland`. |
| `wayland`         | Wayland compositor setup. Mutually exclusive with `xorg`.    |
| `neovim`          | Neovim and its dependencies.                                 |
| `github`          | GitHub CLI and config.                                       |
| `gpg`             | GPG key import and trust setup.                              |
| `docker`          | Docker and Docker Compose.                                   |
| `ufw`             | Firewall rules.                                              |
| `systemd`         | Systemd user services.                                       |
| `crontab`         | Cron jobs.                                                   |
| `xdg-base-dir`    | XDG base directory config.                                   |
| `network-manager` | NetworkManager setup.                                        |
| `ffmpeg`          | FFmpeg and media tools.                                      |

## Running individual roles

```sh
~/ansible-dots/setup --tags ssh
```

Or directly with ansible-playbook:

```sh
ansible-playbook local.yml \
  --become-password-file=.secrets/.become_password \
  --vault-password-file=.secrets/.passphrase \
  --tags ssh
```

Note: if the role has `meta` dependencies they will also run.
