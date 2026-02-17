# home-manager/mutable-files.nix
{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
let
  inherit (config.lib.dag) entryAfter;
  cfg = config.home.mutableFile;

  fileType =
    baseDir:
    { name, config, ... }:
    {
      options = with types; {
        url = mkOption {
          type = str;
          description = "URL of file to fetch";
        };

        path = mkOption {
          type = str;
          default = name;
          apply = p: if hasPrefix "/" p then p else "${baseDir}/${p}";
        };

        extractPath = mkOption {
          type = nullOr str;
          default = null;
        };

        type = mkOption {
          type = enum [
            "git"
            "fetch"
            "archive"
          ];
          default = "fetch";
        };

        extraArgs = mkOption {
          type = listOf str;
          default = [ ];
        };
      };
    };
in
{
  options.home.mutableFile = mkOption (
    with types;
    {
      type = attrsOf (submodule (fileType config.home.homeDirectory));
      default = { };
    }
  );

  config = mkIf (cfg != { }) {
    home.activation.ensureMutableFiles =
      let
        mutableFilesCmds = mapAttrsToList (
          path: value:
          let
            url = escapeShellArg value.url;
            path = escapeShellArg value.path;
            extraArgs = escapeShellArgs value.extraArgs;
          in
          ''
            ${optionalString (value.type == "git") "[ -d ${path} ] || git clone ${extraArgs} ${url} ${path}"}
            ${optionalString (
              value.type == "fetch"
            ) "[ -e ${path} ] || curl ${extraArgs} ${url} --output ${path}"}
            ${optionalString (value.type == "archive") ''
              [ -e ${path} ] || {
                filename=$(curl ${extraArgs} --output-dir /tmp --silent --show-error --write-out '%{filename_effective}' --remote-name --remote-header-name --location ${url})
                ${
                  if (value.extractPath != null) then
                    ''arc extract "/tmp/$filename" ${escapeShellArg value.extractPath} ${path}''
                  else
                    ''arc unarchive "/tmp/$filename" ${path}''
                }
              }
            ''}
          ''
        ) cfg;

        script = pkgs.writeShellScript "fetch-mutable-files" ''
          PATH=${
            makeBinPath (
              with pkgs;
              [
                gnupg
                git
                openssh
              ]
            )
          }
          ${concatStringsSep "\n" mutableFilesCmds}
        '';
      in
      entryAfter [ "reloadSystemd" ] (builtins.toString script);
  };
}
