{ channels, lib, ... }:
final: prev: {
  openconnect-vhotmar = channels.nixpkgs-darwin-stable.openconnect;
}
