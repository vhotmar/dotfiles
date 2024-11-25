{ channels, ... }:
final: prev: {
  inherit (channels.nixpkgs-darwin-stable) tmux;
}
