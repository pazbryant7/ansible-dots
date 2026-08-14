# ansible-dots

Local Ansible provisioning for Void Linux and Artix Linux.

## Run

Clone this repository into the directory where managed repositories should live.
For example:

```text
~/Documents/github/ansible-dots
```

The playbook clones `dotfiles`, `nvim`, and other repositories beside the
`ansible-dots` checkout. Run provisioning through the flake:

```sh
nix develop -c ./setup
```

`setup` changes to the repository directory, creates `.secrets/.passphrase`
and `.secrets/.become_password` interactively when absent, installs the Galaxy
collections, and runs `local.yml`. Secret material in `.secrets/` is required
by several roles and must not be committed or printed.

The first successful run asks for a reboot and records its state under
`~/.local/state/ansible_setup`. Run the command again after reboot to see the
remaining manual steps.

## Roles

The playbook only targets the local host. `common`, `ssh`, and `gpg` always run;
the default roles are listed in `group_vars/all.yml`. `xorg` is the only
implemented display role and always runs with the selected roles.

Pass tags to run a focused set of target roles. Tags replace the default role
list, but bootstrap roles and `xorg` still run:

```sh
nix develop -c ansible-playbook local.yml --tags cli
```

OS-specific role tasks use the normalized distribution names `void.yml` and
`artixlinux.yml`.

## Checks

Run repository tooling through the flake:

```sh
nix develop -c ansible-playbook --syntax-check local.yml
nix develop -c ansible-lint
nix develop -c shellcheck setup
nix develop -c shfmt -d setup
nix develop -c typos
nix fmt -- --ci
```

## Containers

Manual test environments are available for Void and Artix:

```sh
docker compose -f docker/void/docker-compose.yml run --rm ansible
docker compose -f docker/artixlinux/docker-compose.yml run --rm ansible
```

They mount the working tree read-write and `.secrets/` read-only. The latter is
needed for the playbook, while the writable checkout permits Stow's `--adopt`
operation.
