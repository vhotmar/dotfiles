{ channels, ... }:
final: prev:
{
  # inherit (channels.nixpkgs-darwin-stable) bitwarden-cli;

  # https://github.com/NixOS/nixpkgs/issues/339576
  # bitwarden-cli = prev.bitwarden-cli.overrideAttrs (oldAttrs: {
  #   nativeBuildInputs = (oldAttrs.nativeBuildInputs or [ ])
  #     ++ [ prev.llvmPackages_18.stdenv.cc ];
  #   stdenv = prev.llvmPackages_18.stdenv;
  # });
}
