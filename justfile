# ────────────────────────────────────────────────────────────────────────────
# Ansible dev-test justfile
#
# Usage:    just [os=<target>] <recipe>
# Default:  os=arch
#
# Supported targets:
#   arch    → docker/arch/   (archlinux:base)

# Examples:
#   just build                              # build arch (default)
#   just os=arch build                      # build arch
#   just shell=fish compositor=wayland run  # run with overrides
#   just os=arch run-role role=cli          # single role on arch
# ────────────────────────────────────────────────────────────────────────────

# ── Variables ─────────────────────────────────────────────────────────────────

# Target OS — controls which docker/ subfolder is used
os := "arch"

# Playbook variables forwarded as --extra-vars
shell := "zsh"
compositor := "xorg"

# Internals
playbook := "local.yml"
compose := "docker compose"
compose_file := "docker/" + os + "/docker-compose.yml"
service := "ansible"

# ── Help ──────────────────────────────────────────────────────────────────────

# List all available recipes
default:
    @just --list

# ── Secrets ───────────────────────────────────────────────────────────────────

# Write .secrets/ interactively (one-time setup, OS-agnostic)
secrets:
    #!/usr/bin/sh
    mkdir -p .secrets && chmod 700 .secrets
    if [ ! -f .secrets/.become_password ]; then
        printf "Enter sudo/become password: "
        read -r p
        printf "%s" "$p" > .secrets/.become_password
        chmod 600 .secrets/.become_password
    fi
    if [ ! -f .secrets/.passphrase ]; then
        printf "Enter ansible-vault passphrase: "
        read -r v
        printf "%s" "$v" > .secrets/.passphrase
        chmod 600 .secrets/.passphrase
    fi
    @echo "Secrets ready in .secrets/"

# ── Image lifecycle ───────────────────────────────────────────────────────────

# Build the image for the target OS
build:
    {{ compose }} -f {{ compose_file }} build

# Build ignoring layer cache (forces fresh package install)
rebuild:
    {{ compose }} -f {{ compose_file }} build --no-cache

# Pull the latest base image then build
pull:
    #!/usr/bin/env sh
    case "{{ os }}" in
        arch)   docker pull archlinux:base ;;
        *)      echo "ERROR: unknown os '{{ os }}'"; exit 1 ;;
    esac
    just os={{ os }} build

# ── Container lifecycle ───────────────────────────────────────────────────────

# Start the container in the background
up:
    {{ compose }} -f {{ compose_file }} up -d

# Stop and remove the container (image is kept)
down:
    {{ compose }} -f {{ compose_file }} down

# Remove container + image (full reset for this OS target)
clean:
    {{ compose }} -f {{ compose_file }} down --rmi local --volumes --remove-orphans

# Remove containers + images for ALL targets
clean-all:
    just os=arch clean

# ── Playbook execution ────────────────────────────────────────────────────────

# Run the full playbook
run: up
    {{ compose }} -f {{ compose_file }} exec {{ service }} \
        ansible-playbook {{ playbook }} \
            --connection=local \
            --inventory "localhost," \
            --extra-vars "chosen_shell={{ shell }} chosen_compositor={{ compositor }}"
    @just _post

# Dry-run — check mode, no changes applied
check: up
    {{ compose }} -f {{ compose_file }} exec {{ service }} \
        ansible-playbook {{ playbook }} \
            --connection=local \
            --inventory "localhost," \
            --extra-vars "chosen_shell={{ shell }} chosen_compositor={{ compositor }}" \
            --check --diff

# Run with full verbose output (-vvv)
run-verbose: up
    {{ compose }} -f {{ compose_file }} exec {{ service }} \
        ansible-playbook {{ playbook }} \
            --connection=local \
            --inventory "localhost," \
            --extra-vars "chosen_shell={{ shell }} chosen_compositor={{ compositor }}" \
            -vvv
    @just _post

# Run only tasks matching a specific tag  →  just run-tag tag=common
run-tag tag: up
    {{ compose }} -f {{ compose_file }} exec {{ service }} \
        ansible-playbook {{ playbook }} \
            --connection=local \
            --inventory "localhost," \
            --extra-vars "chosen_shell={{ shell }} chosen_compositor={{ compositor }}" \
            --tags "{{ tag }}"

# Run a single role by name  →  just run-role role=zsh
run-role role: up
    just os={{ os }} shell={{ shell }} compositor={{ compositor }} run-tag tag={{ role }}

# ── Linting & syntax ──────────────────────────────────────────────────────────

# Syntax-check the playbook (no connection required)
syntax: up
    {{ compose }} -f {{ compose_file }} exec {{ service }} \
        ansible-playbook {{ playbook }} --syntax-check

# Run ansible-lint
lint: up
    {{ compose }} -f {{ compose_file }} exec {{ service }} \
        ansible-lint {{ playbook }}

# ── Galaxy ────────────────────────────────────────────────────────────────────

# Re-install Galaxy collections for the target OS
galaxy: up
    {{ compose }} -f {{ compose_file }} exec {{ service }} \
        ansible-galaxy collection install -r requirements/{{ os }}.yml

# ── Shell access ──────────────────────────────────────────────────────────────

# Interactive shell inside the container (as testuser)
shell-exec: up
    {{ compose }} -f {{ compose_file }} exec {{ service }} /bin/sh

# Interactive shell as root (useful for debugging become issues)
root: up
    {{ compose }} -f {{ compose_file }} exec --user root {{ service }} /bin/sh

# ── Logs & status ─────────────────────────────────────────────────────────────

# Follow container logs
logs:
    {{ compose }} -f {{ compose_file }} logs --follow {{ service }}

# Show container state
status:
    {{ compose }} -f {{ compose_file }} ps

# Format
format:
    oxfmt --write .

# ── Internal ──────────────────────────────────────────────────────────────────

# Always printed at the end of a full playbook run (mirrors setup script output)
_post:
    @echo ""
    @echo "═══════════════════════════════════════════════"
    @echo "  Manual tasks remaining (cannot be automated)"
    @echo "═══════════════════════════════════════════════"
    @echo "  • Set GTK theme using nwg-look GUI"
    @echo "  • Log in to: Browser, Outlook, Bitwarden,"
    @echo "               GitHub, Google, Twitch"
    @echo "  • Firefox: disable tab preview;"
    @echo "             enable 'switch to last used tab'"
    @echo "═══════════════════════════════════════════════"
