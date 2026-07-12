{ inputs }:
let
  fenixOverlay = inputs.fenix.overlays.default;

  claudeCodeOverlay = inputs.claude-code-overlay.overlays.default;

  stablePackagesOverlay = final: prev: {
    stable = import inputs.nixpkgs-stable {
      inherit (final) system;

      config = {
        allowUnfree = true;
        allowBroken = true;
      };
    };
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

  # TODO(remove once nixpkgs ld64 hardening is reverted):
  #   nixpkgs enabled libc++ hardening in ld64 (the cctools linker) in PR #536363
  #   ("glib: fix build on Darwin", merged 2026-06-29). On macOS Tahoe this makes
  #   ld itself crash (Trace/BPT trap: 5 -> exit 133) while linking many packages,
  #   including lima (#540426) and terminal-notifier (cf. noti #540408). Workaround:
  #   link these with LLVM's lld instead of cctools ld, matching nixpkgs' own
  #   per-package fixes (e.g. starship #540463).
  #   Waiting on nixpkgs PR #536365 ("ld64: disable hardening again"); drop this
  #   overlay once that reaches nixpkgs-unstable.
  ld64HardeningWorkaroundOverlay = final: prev:
    let
      useLld = pkg: pkg.overrideAttrs (old: {
        nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ final.llvmPackages.lld ];
        NIX_CFLAGS_LINK = "${old.NIX_CFLAGS_LINK or ""} -fuse-ld=lld";
      });
    in
    prev.lib.optionalAttrs prev.stdenv.hostPlatform.isDarwin {
      lima = useLld prev.lima;
      terminal-notifier = useLld prev.terminal-notifier;
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
  vpnSliceOverlay
  yknotifyOverlay
  ld64HardeningWorkaroundOverlay
  stablePackagesOverlay
]
