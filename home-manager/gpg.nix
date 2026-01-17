# home-manager/gpg.nix
# GPG agent configuration with SSH support
# Adapted from nix/modules/home/security/gpg/default.nix
{ config, pkgs, lib, ... }:

let
  cfg = config.services.gpg-agent;
  gpgPkg = config.programs.gpg.package;
  homedir = config.programs.gpg.homedir;

  isLinux = pkgs.stdenv.isLinux;
  isDarwin = pkgs.stdenv.isDarwin;

  gpgSshSupportStr = ''
    ${gpgPkg}/bin/gpg-connect-agent updatestartuptty /bye > /dev/null
  '';

  gpgInitStr = ''
    GPG_TTY="$(tty)"
    export GPG_TTY
  '' + lib.optionalString cfg.enableSshSupport gpgSshSupportStr;

  gpgFishInitStr = ''
    set -gx GPG_TTY (tty)
  '' + lib.optionalString cfg.enableSshSupport gpgSshSupportStr;
in
{
  programs.gpg.enable = true;

  services.gpg-agent = {
    enableSshSupport = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
    enableFishIntegration = true;
  };

  # Linux: use the gpg-agent service
  services.gpg-agent.enable = lib.mkIf isLinux true;

  # Darwin: manual gpg-agent.conf and shell integration
  home.file."${homedir}/gpg-agent.conf" = lib.mkIf isDarwin {
    text = lib.concatStringsSep "\n" (
      lib.optional cfg.enableSshSupport "enable-ssh-support"
      ++ lib.optional cfg.grabKeyboardAndMouse "grab"
      ++ lib.optional (!cfg.enableScDaemon) "disable-scdaemon"
      ++ lib.optional (cfg.defaultCacheTtl != null) "default-cache-ttl ${toString cfg.defaultCacheTtl}"
      ++ lib.optional (cfg.defaultCacheTtlSsh != null) "default-cache-ttl-ssh ${toString cfg.defaultCacheTtlSsh}"
      ++ lib.optional (cfg.maxCacheTtl != null) "max-cache-ttl ${toString cfg.maxCacheTtl}"
      ++ lib.optional (cfg.maxCacheTtlSsh != null) "max-cache-ttl-ssh ${toString cfg.maxCacheTtlSsh}"
      ++ lib.optional (cfg.pinentry.package != null) "pinentry-program ${lib.getExe cfg.pinentry.package}"
      ++ [ cfg.extraConfig ]
    );
  };

  home.sessionVariablesExtra = lib.mkIf (isDarwin && cfg.enableSshSupport) ''
    if [[ -z "$SSH_AUTH_SOCK" ]]; then
      export SSH_AUTH_SOCK="$(${gpgPkg}/bin/gpgconf --list-dirs agent-ssh-socket)"
    fi
  '';

  programs.bash.initExtra = lib.mkIf (isDarwin && cfg.enableBashIntegration) gpgInitStr;
  programs.zsh.initExtra = lib.mkIf (isDarwin && cfg.enableZshIntegration) gpgInitStr;
  programs.fish.interactiveShellInit = lib.mkIf (isDarwin && cfg.enableFishIntegration) gpgFishInitStr;
}
