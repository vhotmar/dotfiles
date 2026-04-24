# overlays/default.nix
{ inputs }:
let
  # Fenix overlay for Rust toolchain
  fenixOverlay = inputs.fenix.overlays.default;

  # Claude Code overlay for pre-built binaries
  claudeCodeOverlay = inputs.claude-code-overlay.overlays.default;

  # TODO(2026-04-24): retry dropping this when Hydra consistently has aarch64-darwin
  # direnv builds cached. direnv's zsh checkPhase hangs under the Nix sandbox on
  # aarch64-darwin when building from source; Hydra already runs the tests upstream.
  direnvOverlay = final: prev: {
    direnv = prev.direnv.overrideAttrs (_: { doCheck = false; });
  };

  # Custom vpn-slice with newer commit
  vpnSliceOverlay = final: prev: {
    vpn-slice-vhotmar = prev.vpn-slice.overrideAttrs (
      _: p: {
        version = "git";
        src = prev.fetchFromGitHub {
          owner = "dlenski";
          repo = p.pname;
          rev = "4e26adbfd14de2be5e77933e96d353ea7d200107";
          sha256 = "sha256-x9Y36/wy0HhBc7tT6rG9ehGtzkoTPMj2jAOypX6yQRk";
        };
      }
    );
  };

  # yknotify: macOS notifications on YubiKey touch prompts
  yknotifyOverlay = final: prev: {
    yknotify = prev.buildGoModule {
      pname = "yknotify";
      version = "unstable-2025-02-12";
      src = prev.fetchFromGitHub {
        owner = "noperator";
        repo = "yknotify";
        rev = "0c773bdadedb137d02d95c79430fa5e0442c9950";
        hash = "sha256-AhTr3lzYS6z1XoqVC2IIdJoDVdWajrbGhOe20dVQrGQ=";
      };
      vendorHash = null;
      meta = {
        description = "Notify when YubiKey is waiting for a touch";
        homepage = "https://github.com/noperator/yknotify";
        license = prev.lib.licenses.mit;
        platforms = prev.lib.platforms.darwin;
      };
    };
  };
in
[
  fenixOverlay
  claudeCodeOverlay
  direnvOverlay
  vpnSliceOverlay
  yknotifyOverlay
]
