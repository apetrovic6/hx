{
  pkgs,
  lib,
}: let
  # Small helpers to keep things tidy
  mkLang = {
    name,
    fileTypes ? [],
    servers ? [],
    roots ? [],
  }:
    {
      inherit name;
      "file-types" = fileTypes;
      "language-servers" = servers;
    }
    // (
      if roots != []
      then {"roots" = roots;}
      else {}
    );

  mkServer = {
    cmd,
    args ? [],
    cfg ? {},
  }: {
    command = cmd;
    inherit args;
    config = cfg;
  };
in {
  languages = [
    (mkLang {
      name = "yaml";
      fileTypes = ["yaml" "yml"];
      servers = ["yaml-language-server"];
    })
  ];

  languageServers = {
    "yaml-language-server" = mkServer {
      cmd = "yaml-language-server";
      args = ["--stdio"];
      cfg = {
        yaml = {
          validate = true;
          hover = true;
          completion = true;
          format = {enable = true;};
          schemas = {
            kubernetes = [
              "*deployment*.yaml"
              "*service*.yaml"
              "*.y{a,}ml"
              "*configmap*.yaml"
              "*secret*.yaml"
              "*pod*.yaml"
              "*namespace*.yaml"
              "*ingress*.yaml"
            ];
            "https://raw.githubusercontent.com/SchemaStore/schemastore/master/src/schemas/json/kustomization.json" = ["*kustomization.yaml" "*kustomize.yaml"];
            "https://raw.githubusercontent.com/argoproj/argo-workflows/master/api/jsonschema/schema.json" = ["*workflow*.yaml" "*template*.yaml"];
          };
        };
      };
    };
  };

}
