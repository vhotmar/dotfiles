{ channels, ... }:
final: prev: {
  inherit (channels.nixpkgs-darwin-stable) sesh;
}
