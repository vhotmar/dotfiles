{ ... }:
final: prev: {
  vpn-slice-vhotmar = prev.vpn-slice.overrideAttrs (_: p: {
    version = "git";

    src = prev.fetchFromGitHub {
      owner = "dlenski";
      repo = p.pname;
      rev = "4e26adbfd14de2be5e77933e96d353ea7d200107";
      sha256 = "sha256-x9Y36/wy0HhBc7tT6rG9ehGtzkoTPMj2jAOypX6yQRk";
    };
  });
}
