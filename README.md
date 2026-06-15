# Ansible Dev-Test Environment

A Docker-based sandbox for testing Ansible roles before running them on bare
metal. Everything is driven through `just` from the repo root. No need to touch
the `docker/` internals directly.

---

## How it works

```
┌─────────────────────────────────────────────────────────────┐
│  Host machine                                               │
│                                                             │
│  your repo/  ──bind-mount──►  /ansible  (container)        │
│  .secrets/   ──bind-mount──►  /ansible/.secrets  (ro)      │
│                                                             │
│  just [os=arch] <recipe>                             │
│       └─► docker compose -f docker/<os>/docker-compose.yml │
│                 └─► ansible-playbook local.yml              │
└─────────────────────────────────────────────────────────────┘
```

The `os` variable in the justfile routes every command to the right
`docker/<os>/` subfolder, so switching targets is a single flag.

---

## Project structure

```
.
├── docker/
│   ├── arch/
│   │   ├── Dockerfile          # archlinux:base + ansible + galaxy (arch)
│   │   └── docker-compose.yml
├── requirements/
│   ├── arch.yml                # kewlfft.aur + moreati.uv
├── roles/
├── local.yml
└── justfile                    ← single entrypoint for everything
```

### Why two requirements files?

`kewlfft.aur` is an AUR-only module — it has no meaning outside Arch.
`moreati.uv` is cross-platform and is included in both files. Each Dockerfile
bakes in the right requirements at build time so `just run` never re-downloads
collections on every test cycle.

### macOS note

There is no official macOS Docker base image. Docker on macOS runs inside a
Linux VM (Docker Desktop), so you can only run Linux containers. If you need to
validate macOS-specific roles, the only option is running the playbook directly
on a macOS host — no container path exists for it.

---

## Prerequisites

| Tool                                          | Minimum version           | Install (Arch)          |
| --------------------------------------------- | ------------------------- | ----------------------- |
| [Docker](https://docs.docker.com/get-docker/) | 24+ (Compose v2 built-in) | `sudo pacman -S docker` |
| [just](https://github.com/casey/just)         | 1.14+                     | `sudo pacman -S just`   |

---

## Quick start

### 1. Write secrets (one-time)

```sh
just secrets
```

Prompts for your sudo/become password and ansible-vault passphrase and writes
them to `.secrets/` with `chmod 600`. The directory is git-ignored and never
baked into any image.

### 2. Build the image

```sh
just build              # arch (default)
```

Galaxy collections are installed during the build step, so subsequent runs are
fast. Only re-run `just rebuild` when `requirements/<os>.yml` changes or after a
long gap (Arch packages drift on rolling release).

### 3. Run the playbook

```sh
just run                                    # arch, zsh, xorg
just shell=fish compositor=wayland run      # override defaults
```

The manual tasks that cannot be automated are always printed at the end of every
full run.

---

## Recipe reference

### Secrets

| Recipe         | What it does                                                            |
| -------------- | ----------------------------------------------------------------------- |
| `just secrets` | Write `.secrets/` interactively (all OS targets share the same secrets) |

### Image & container

| Recipe           | What it does                               |
| ---------------- | ------------------------------------------ |
| `just build`     | Build the image for `os`                   |
| `just rebuild`   | Build with `--no-cache`                    |
| `just pull`      | Pull latest base image then build          |
| `just up`        | Start container in background              |
| `just down`      | Stop and remove container                  |
| `just clean`     | Remove container + image for `os`          |
| `just clean-all` | Remove containers + images for all targets |

### Playbook execution

| Recipe                      | What it does               |
| --------------------------- | -------------------------- |
| `just run`                  | Full playbook run          |
| `just check`                | Dry-run (`--check --diff`) |
| `just run-verbose`          | Full run with `-vvv`       |
| `just run-tag tag=<name>`   | Run tasks matching a tag   |
| `just run-role role=<name>` | Run a single role          |

### Linting & syntax

| Recipe        | What it does                      |
| ------------- | --------------------------------- |
| `just syntax` | `ansible-playbook --syntax-check` |
| `just lint`   | `ansible-lint`                    |

### Galaxy

| Recipe        | What it does                                               |
| ------------- | ---------------------------------------------------------- |
| `just galaxy` | Re-install collections for `os` inside a running container |

### Utilities

| Recipe            | What it does             |
| ----------------- | ------------------------ |
| `just shell-exec` | sh session as `testuser` |
| `just root`       | sh session as root       |
| `just logs`       | Follow container logs    |
| `just status`     | Show container state     |

---

## Variables

All variables can be overridden on the command line:

| Variable     | Default     | Description                                   |
| ------------ | ----------- | --------------------------------------------- |
| `os`         | `arch`      | Target OS (`arch`)                |
| `shell`      | `zsh`       | Passed as `chosen_shell` to the playbook      |
| `compositor` | `xorg`      | Passed as `chosen_compositor` to the playbook |
| `playbook`   | `local.yml` | Playbook file to run                          |

```sh
just os=arch shell=fish compositor=wayland run
just os=arch run-role role=neovim
```

---

## Adding a new OS target

1. Create `docker/<os>/Dockerfile` and `docker/<os>/docker-compose.yml`
   following the existing pattern (point `context:` to `../../`).
2. Create `requirements/<os>.yml` with the relevant Galaxy collections.
3. The justfile picks up the new target automatically via the `os` variable — no
   changes needed.

---

## Tips

**Iterating on one role** — skip the full run and target just what you're
working on:

```sh
just run-role role=neovim
just os=arch run-role role=cli
```

**Checking before applying** — always a good idea for destructive roles:

```sh
just check
just os=arch check
```

**Arch package drift** — rolling release means cached layers go stale. If
`pacman -S` starts failing with signature errors during a run, force a fresh
build:

```sh
just rebuild
```

**Debugging inside the container** — drop into a shell and run ansible manually
with full verbosity:

```sh
just shell-exec
ansible-playbook local.yml --connection=local --inventory "localhost," \
  --become-password-file=.secrets/.become_password \
  --vault-password-file=.secrets/.passphrase \
  --extra-vars "chosen_shell=zsh chosen_compositor=xorg" -vvv
```
