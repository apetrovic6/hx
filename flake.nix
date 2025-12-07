{
  description = "Helix configuration";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    treefmt-nix.url = "github:numtide/treefmt-nix";
    wrappers.url = "github:lassulus/wrappers";
  };

  outputs = inputs @ {
    flake-parts,
    wrappers,
    ...
  }:
    flake-parts.lib.mkFlake {inherit inputs;} {
      imports = [inputs.treefmt-nix.flakeModule];

      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
        "x86_64-darwin"
      ];

      perSystem = {
        pkgs,
        lib,
        system,
        ...
      }: let
toml = pkgs.formats.toml {};

  # path to your languages config
  cfgLangs = ./languages/default.toml;

  baseSettings = import ./settings.nix { inherit lib pkgs; };

  # 🔧 hard-coded Helix theme name (must exist in Helix)
  themeName = "everforest_dark";  # or "base16_default_dark", "tokyonight", etc.

  cfg = toml.generate "helix-config" (baseSettings // {
    theme = themeName;
  });

  launcher = pkgs.writeShellScriptBin "hx" ''
    set -euo pipefail

    # Use a fresh temporary XDG config dir each run
    tmpcfg="$(mktemp -d)"
    mkdir -p "$tmpcfg/helix"

    # Symlink generated config + languages.toml into the temp config dir
    ln -s '${cfg}'      "$tmpcfg/helix/config.toml"
    ln -s '${cfgLangs}' "$tmpcfg/helix/languages.toml"

    # Make Helix look there for config
    export XDG_CONFIG_HOME="$tmpcfg"

    # Just run Helix directly, no wrappers
    exec ${pkgs.helix}/bin/hx "$@"

        '';
      in {
        packages.default = launcher;

        treefmt = {
          projectRootFile = "flake.nix";
          programs.alejandra.enable = true;
        };
      };
    };
}
