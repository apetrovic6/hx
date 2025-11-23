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
      imports = [
        inputs.treefmt-nix.flakeModule
      ];

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

        # ⬇️ NEW: import editor + keys from a separate file
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

        launcher = pkgs.writeShellScriptBin "hx" ''
          unset HELIX_RUNTIME
          export XDG_CONFIG_HOME="$HOME/.config"

          if [ -f "$HOME/.config/helix/themes/stylix.toml" ]; then
            exec ${wrapped.wrapper}/bin/hx -c ${cfgStylix} "$@"
          else
            exec ${wrapped.wrapper}/bin/hx -c ${cfgFallback} "$@"
          fi
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
