{
  description = "Description for the project";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    wrappers.url = "github:lassulus/wrappers";
  };

  outputs =
    inputs@{ flake-parts, wrappers, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [ ];

      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
        "x86_64-darwin"
      ];

     perSystem = { pkgs, lib,  system, ... }:
let
  tomlFmt = pkgs.formats.toml { };

  # ---- single source of truth for Helix settings ----
  mySettings = {
    theme = "stylix";
    editor = {
      bufferline = "multiple";
      "color-modes" = true;
      "true-color" = true;
      "auto-pairs" = false;
      "line-number" = "relative";
      "inline-diagnostics" = { "cursor-line" = "hint"; };
      "cursor-shape" = { insert = "bar"; normal = "block"; select = "underline"; };
      statusline = {
        left  = [ "mode" "spinner" "file-name" ];
        right = [ "diagnostics" "selections" "position" "file-encoding" "file-line-ending" "file-type" ];
        separator = "│";
      };
    };
    keys = {
      normal = {
        # Lazygit
        "C-g" = [
          ":new"
          ":insert-output ${lib.getExe pkgs.lazygit}"
          ":buffer-close!"
          ":redraw"
        ];

        # Yazi
        "C-y" = [
          ":sh rm -f /tmp/unique-file"
          ":insert-output ${lib.getExe pkgs.yazi} %{buffer_name} --chooser-file=/tmp/unique-file"
          # reset alt-screen + bracketed paste in TTY
          ":insert-output echo \"\\x1b[?1049h\\x1b[?2004h\" > /dev/tty"
          ":open %sh{cat /tmp/unique-file}"
          ":redraw"
        ];
      };
    };
  };

  # generate a TOML file in the store for -c
  cfgPath = tomlFmt.generate "helix-config" mySettings;

  # your original wrapper (do NOT force XDG_CONFIG_HOME to a store path)
  wrapped = inputs.wrappers.wrapperModules.helix.apply {
    config = {
      inherit pkgs;
      settings = mySettings;

      # make sure Helix uses the real user config dir at runtime
       env.XDG_CONFIG_HOME = lib.mkForce "\$HOME/.config";
      # (omit HELIX_RUNTIME unless you truly need it)
    };
  };

  # re-wrap hx to always pass -c <store-config>
hxWithC = pkgs.symlinkJoin {
  name = "helix-with-wrapper-config";
  paths = [ wrapped.wrapper ];
  buildInputs = [ pkgs.makeWrapper ];
  postBuild = ''
    wrapProgram "$out/bin/hx" \
      --unset HELIX_RUNTIME \
      --set XDG_CONFIG_HOME "$HOME/.config" \
      --add-flags "-c ${cfgPath}"
  '';
};in {
  packages.default = hxWithC;
}
;
    };
}
