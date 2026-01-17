# overlays/default.nix
{ inputs }:
let
  # Fenix overlay for Rust toolchain
  fenixOverlay = inputs.fenix.overlays.default;

  # Custom vpn-slice with newer commit
  vpnSliceOverlay = final: prev: {
    vpn-slice-vhotmar = prev.vpn-slice.overrideAttrs (_: p: {
      version = "git";
      src = prev.fetchFromGitHub {
        owner = "dlenski";
        repo = p.pname;
        rev = "4e26adbfd14de2be5e77933e96d353ea7d200107";
        sha256 = "sha256-x9Y36/wy0HhBc7tT6rG9ehGtzkoTPMj2jAOypX6yQRk";
      };
    });
  };

  # Tmux from stable channel (for darwin compatibility)
  tmuxOverlay = final: prev: {
    tmux-stable = inputs.nixpkgs-darwin-stable.legacyPackages.${prev.system}.tmux;
  };
in
[
  fenixOverlay
  vpnSliceOverlay
  tmuxOverlay
]
