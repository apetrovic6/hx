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

        baseSettings = {
          # everything except the theme
          editor = {
            bufferline = "multiple";
            "color-modes" = true;
            "true-color" = true;
            "auto-pairs" = false;
            "line-number" = "relative";
            "inline-diagnostics" = {"cursor-line" = "hint";};
            "cursor-shape" = {
              insert = "bar";
              normal = "block";
              select = "underline";
            };
            statusline = {
              left = ["mode" "spinner" "file-name"];
              right = ["diagnostics" "selections" "position" "file-encoding" "file-line-ending" "file-type"];
              separator = "│";
            };
          };
          keys.normal = {
            "C-g" = [
              ":new"
              ":insert-output ${lib.getExe pkgs.lazygit}"
              ":buffer-close!"
              ":redraw"
            ];
            "C-y" = [
              ":sh rm -f /tmp/unique-file"
              ":insert-output ${lib.getExe pkgs.yazi} %{buffer_name} --chooser-file=/tmp/unique-file"
              ":insert-output echo \"\\x1b[?1049h\\x1b[?2004h\" > /dev/tty"
              ":open %sh{cat /tmp/unique-file}"
              ":redraw"
            ];
          };
        };

        cfgStylix = toml.generate "helix-config-stylix" (baseSettings // {theme = "stylix";});
        cfgFallback = toml.generate "helix-config-fallback" (baseSettings // {theme = "gruvbox";});

        # your existing wrappers build (keep $HOME config visible)
        wrapped = inputs.wrappers.wrapperModules.helix.apply {
          config = {
            inherit pkgs;
            settings = baseSettings // {theme = "stylix";};
            env.XDG_CONFIG_HOME = lib.mkForce "\$HOME/.config";
          };
        };

        # write a smart launcher that chooses config at runtime
        launcher = pkgs.writeShellScriptBin "hx" ''
          # make sure Helix can see user config/themes
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
          programs.alejandra.enable = true; # Nix formatter
        };
      };
    };
}
