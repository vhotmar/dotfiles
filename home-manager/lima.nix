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
  imports = [ ./linux.nix ];

  home.homeDirectory = lib.mkForce "/home/${host.username}.guest";

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
}
