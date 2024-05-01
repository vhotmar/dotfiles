{ lib, config, pkgs, ... }:

# Copy from https://github.com/nix-community/home-manager/blob/2af7c78b7bb9cf18406a193eba13ef9f99388f49/modules/services/gpg-agent.nix
# basically using all of hte options settings except vlib.security.gpg.enable with all the settings from services.gpg-agent
with lib;
let
  cfgO = config.vlib.security.gpg;
  cfg = config.services.gpg-agent;

  isLinux = pkgs.stdenv.isLinux;
  isDarwin = pkgs.stdenv.isDarwin;

  gpgPkg = config.programs.gpg.package;

  homedir = config.programs.gpg.homedir;

  gpgSshSupportStr = ''
    ${gpgPkg}/bin/gpg-connect-agent updatestartuptty /bye > /dev/null
  '';

  gpgInitStr = ''
    GPG_TTY="$(tty)"
    export GPG_TTY
  '' + optionalString cfg.enableSshSupport gpgSshSupportStr;

  gpgFishInitStr = ''
    set -gx GPG_TTY (tty)
  '' + optionalString cfg.enableSshSupport gpgSshSupportStr;

  gpgNushellInitStr = ''
    $env.GPG_TTY = (tty)
  '' + optionalString cfg.enableSshSupport ''
    ${gpgPkg}/bin/gpg-connect-agent updatestartuptty /bye | ignore

    $env.SSH_AUTH_SOCK = ($env.SSH_AUTH_SOCK? | default (${gpgPkg}/bin/gpgconf --list-dirs agent-ssh-socket))
  '';

in {
  options.vlib.security.gpg = { enable = mkEnableOption "GPG"; };

  config = mkIf cfgO.enable (mkMerge [
    {
      programs.gpg = { enable = true; };

      services.gpg-agent = { enableSshSupport = true; };
    }

    (mkIf isLinux { services.gpg-agent.enable = true; })

    (mkIf isDarwin {
      home.file."${homedir}/gpg-agent.conf".text = concatStringsSep "\n"
        (optional (cfg.enableSshSupport) "enable-ssh-support"
          ++ optional cfg.grabKeyboardAndMouse "grab"
          ++ optional (!cfg.enableScDaemon) "disable-scdaemon"
          ++ optional (cfg.defaultCacheTtl != null)
          "default-cache-ttl ${toString cfg.defaultCacheTtl}"
          ++ optional (cfg.defaultCacheTtlSsh != null)
          "default-cache-ttl-ssh ${toString cfg.defaultCacheTtlSsh}"
          ++ optional (cfg.maxCacheTtl != null)
          "max-cache-ttl ${toString cfg.maxCacheTtl}"
          ++ optional (cfg.maxCacheTtlSsh != null)
          "max-cache-ttl-ssh ${toString cfg.maxCacheTtlSsh}"
          ++ optional (cfg.pinentryPackage != null)
          "pinentry-program ${lib.getExe cfg.pinentryPackage}"
          ++ [ cfg.extraConfig ]);

      home.sessionVariablesExtra = optionalString cfg.enableSshSupport ''
        if [[ -z "$SSH_AUTH_SOCK" ]]; then
          export SSH_AUTH_SOCK="$(${gpgPkg}/bin/gpgconf --list-dirs agent-ssh-socket)"
        fi
      '';

      programs.bash.initExtra = mkIf cfg.enableBashIntegration gpgInitStr;
      programs.zsh.initExtra = mkIf cfg.enableZshIntegration gpgInitStr;
      programs.fish.interactiveShellInit =
        mkIf cfg.enableFishIntegration gpgFishInitStr;

      programs.nushell.extraEnv =
        mkIf cfg.enableNushellIntegration gpgNushellInitStr;
    })

  ]);
}

