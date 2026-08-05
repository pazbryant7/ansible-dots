{
  description = "Full-stack dev environment (replaces Mason toolchain)";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };
      in
      {
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            # ── bash ─────────────────────────────
            shfmt
            shellcheck
            shellharden
            bash-language-server

            # ── ansible ──────────────────────────
            ansible
            ansible-lint

            # ── language agnostic ────────────────
            typos

            # ── formatters ───────────────────────
            oxfmt

            # ── LSP ──────────────────────────────
            yaml-language-server
          ];

          shellHook = ''
            if [ -z "$IN_NIX_ZSH" ]; then
              export IN_NIX_ZSH=1
              exec zsh
            fi
          '';
        };

        formatter = pkgs.nixfmt-tree;
      }
    );
}
