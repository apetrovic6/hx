{
  description = "Description for the project";

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

        cfgLangs = (builtins.toString ./languages/default.toml);

        baseSettings = import ./settings.nix {inherit lib pkgs;};

        cfgStylix = toml.generate "helix-config-stylix" (baseSettings // {theme = "stylix";});
        cfgFallback = toml.generate "helix-config-fallback" (baseSettings // {theme = "gruvbox";});

        wrapped = inputs.wrappers.wrapperModules.helix.apply {
          config = {
            inherit pkgs;
            settings = baseSettings // {theme = "stylix";};
            env.XDG_CONFIG_HOME = lib.mkForce "\$HOME/.config";
          };
        };

        # --- FIX: spawn a tiny config dir with BOTH files and run hx there ---
        launcher = pkgs.writeShellScriptBin "hx" ''
          set -euo pipefail

          # Make yaml-language-server available (adjust if needed)
          export PATH="${pkgs.nodePackages.yaml-language-server}/bin:${pkgs.nodejs}/bin:$PATH"

          # Pick which config to use (always sets cfgFile)
          if [ -f "$HOME/.config/helix/themes/stylix.toml" ]; then
            cfgFile='${cfgStylix}'
          else
            cfgFile='${cfgFallback}'
          fi

          # Cross-platform mktemp: try GNU, then BSD, then fallback
          tmpcfg=""
          if tmpcfg="$(mktemp -d 2>/dev/null)"; then
            :
          elif tmpcfg="$(mktemp -d -t hxcfg 2>/dev/null)"; then
            :
          else
            base="${TMPDIR:-/tmp}"
            mkdir -p "$base"
            tmpcfg="$base/hxcfg.$RANDOM.$RANDOM.$RANDOM"
            mkdir -p "$tmpcfg"
          fi

          mkdir -p "$tmpcfg/helix"

          # languages.toml you generated in the flake
          ln -s '${cfgLangs}' "$tmpcfg/helix/languages.toml"
          # chosen config.toml
          ln -s "$cfgFile"     "$tmpcfg/helix/config.toml"

          # Make Stylix themes visible if present
          if [ -d "$HOME/.config/helix/themes" ]; then
            ln -s "$HOME/.config/helix/themes" "$tmpcfg/helix/themes"
          fi

          # Point Helix at this temp config dir
          unset HELIX_RUNTIME
          export XDG_CONFIG_HOME="$tmpcfg"

          exec ${wrapped.wrapper}/bin/hx "$@"
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
