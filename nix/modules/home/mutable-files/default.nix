{ config, lib, pkgs, ... }:

with lib;
let
  inherit (config.lib.dag) entryAfter;

  cfg = config.home.mutableFile;

  fileType = baseDir:
    { name, config, ... }: {
      options = with types; {
        url = mkOption {
          type = str;
          description = mkDoc ''
            The URL of the file to be fetched.
          '';
          example = "https://github.com/foo-dogsquared/dotfiles.git";
        };

        path = mkOption {
          type = str;
          description = mkDoc ''
            The path of the mutable file. By default, it will be relative to the
            home directory.
          '';
          example =
            literalExpression "\${config.xdg.userDirs.documents}/top-secret";
          default = name;
          apply = p: if hasPrefix "/" p then p else "${baseDir}/${p}";
        };

        extractPath = mkOption {
          type = nullOr str;
          description = mkDoc ''
            The path within the archive to be extracted. This is only used if the
            type is `archive`. If the value is `null` then it will extract the
            whole archive into the directory.
          '';
          default = null;
          example = "path/inside/of/the/archive";
        };

        type = mkOption {
          type = enum [ "git" "fetch" "archive" ];
          description = mkDoc ''
            Type that configures the behavior for fetching the URL.

            This accept only certain keywords.

            - For `fetch`, the file will be fetched with `curl`.
            - For `git`, it will be fetched with `git clone`.
            - For `archive`, the file will be fetched with `curl` and extracted
            before putting the file.

            The default type is `fetch`.
          '';
          default = "fetch";
          example = "git";
        };

        extraArgs = mkOption {
          type = listOf str;
          description = mkDoc ''
            A list of extra arguments to be included with the fetch command. Take
            note of the commands used for each type as documented from
            `config.home.mutableFile.<name>.type`.
          '';
          default = [ ];
          example = [ "--depth" "1" ];
        };
      };
    };
in {
  options.home.mutableFile = mkOption (with types; {
    type = attrsOf (submodule (fileType config.home.homeDirectory));
    description = mkDoc ''
      An attribute set of mutable files and directories to be declaratively put
      into the home directory. Take note this is not exactly pure (or
      idempotent) as it will only do its fetching when the designated file is
      missing.
    '';
    default = { };
    example = literalExpression ''
      {
        "library/dotfiles" = {
          url = "https://github.com/foo-dogsquared/dotfiles.git";
          type = "git";
        };

        "library/projects/keys" = {
          url = "https://example.com/file.zip";
          type = "archive";
        };
      }
    '';
  });

  config = mkIf (cfg != { }) {
    home.activation.ensureMutableFiles = let
      mutableFilesCmds = mapAttrsToList (path: value:
        let
          url = escapeShellArg value.url;
          path = escapeShellArg value.path;
          extraArgs = escapeShellArgs value.extraArgs;
        in ''
          ${optionalString (value.type == "git")
          "[ -d ${path} ] || git clone ${extraArgs} ${url} ${path}"}
          ${optionalString (value.type == "fetch")
          "[ -e ${path} ] || curl ${extraArgs} ${url} --output ${path}"}
          ${optionalString (value.type == "archive") ''
            [ -e ${path} ] || {
              filename=$(curl ${extraArgs} --output-dir /tmp --silent --show-error --write-out '%{filename_effective}' --remote-name --remote-header-name --location ${url})
              ${
                if (value.extractPath != null) then
                  ''
                    arc extract "/tmp/$filename" ${
                      escapeShellArg value.extractPath
                    } ${path}''
                else
                  ''arc unarchive "/tmp/$filename" ${path}''
              }
            }
          ''}
        '') cfg;

      script = pkgs.writeShellScript "fetch-mutable-files" ''
        PATH=${makeBinPath (with pkgs; [ gnupg git openssh ])}
        ${concatStringsSep "\n" mutableFilesCmds}
      '';
    in entryAfter [ "reloadSystemd" ] (builtins.toString script);
  };
}

