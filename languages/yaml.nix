{ pkgs, lib }:
{
  # One language, one server
  languages = [
    {
      name = "yaml";
      "file-types" = [ "yaml" "yml" ];
      "language-servers" = [ "yaml-language-server" ];
    }
  ];

  "language-server" = {
    "yaml-language-server" = {
      command = "yaml-language-server";
      args = [ "--stdio" ];
      # minimal: no extra config yet
    };
  };
}
