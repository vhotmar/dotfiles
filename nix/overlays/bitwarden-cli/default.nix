{ channels, ... }:
final: prev: {
  inherit (channels.nixpkgs-darwin-stable) bitwarden-cli;
}
