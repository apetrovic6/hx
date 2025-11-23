{
  lib,
  pkgs,
}: {
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
}
