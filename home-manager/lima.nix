# home-manager/lima.nix
# home-manager config for the Lima VM on a macOS host.
# Lima puts the guest user's HOME at /home/<user>.guest to avoid colliding
# with the /Users/<user> mount path from the macOS host.
{
  config,
  pkgs,
  lib,
  host,
  ...
}:

{
  imports = [
    ./linux.nix
    ./opencode.nix
  ];

  home.homeDirectory = lib.mkForce "/home/${host.username}.guest";

  # The MLX server runs on the macOS host and binds only its loopback. Lima's
  # user-mode NAT resolves host.lima.internal to the gateway (192.168.5.2) and
  # forwards to that loopback, so the guest is a client without the host
  # listening on any LAN interface. Verified: a host service bound to
  # 127.0.0.1 is reachable from here, one bound nowhere is not.
  localLlm.host = "host.lima.internal";

  home.mutableFile = lib.mkForce { };

  # Expose Podman's vendor user units and enable its rootless Docker-compatible API socket.
  # The socket is activated on demand by podman.service and listens at %t/podman/podman.sock.
  systemd.user.packages = [ pkgs.podman ];
  systemd.user.sockets.podman = {
    Unit = {
      Description = "Podman API Socket";
      Documentation = [ "man:podman-system-service(1)" ];
    };

    Socket = {
      ListenStream = "%t/podman/podman.sock";
      SocketMode = "0660";
    };

    Install = {
      WantedBy = [ "sockets.target" ];
    };
  };

  xdg.configFile."containers/policy.json".text = builtins.toJSON {
    default = [
      { type = "insecureAcceptAnything"; }
    ];

    transports = {
      docker = {
        "docker.io" = [
          { type = "insecureAcceptAnything"; }
        ];
        "ghcr.io" = [
          { type = "insecureAcceptAnything"; }
        ];
        "" = [
          { type = "insecureAcceptAnything"; }
        ];
      };
    };
  };
}
