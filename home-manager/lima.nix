# home-manager/lima.nix
# home-manager config for the Lima VM on a macOS host.
# Lima puts the guest user's HOME at /home/<user>.guest to avoid colliding
# with the /Users/<user> mount path from the macOS host.
{
  config,
  pkgs,
  lib,
  ...
}:

{
  imports = [ ./linux.nix ];

  home.homeDirectory = lib.mkForce "/home/vhotmar.guest";

  home.mutableFile = lib.mkForce { };
}
