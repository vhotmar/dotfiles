{ inputs }:
let
  fenixOverlay = inputs.fenix.overlays.default;

  claudeCodeOverlay = inputs.claude-code-overlay.overlays.default;

  codexCliOverlay = final: _prev: {
    codex = inputs.codex-cli-nix.packages.${final.stdenv.hostPlatform.system}.default;
  };

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

  qmdOverlay =
    final: prev:
    let
      upstream = inputs.qmd.packages.${prev.stdenv.hostPlatform.system}.default;
      isAarch64Linux = prev.stdenv.hostPlatform.system == "aarch64-linux";

      # Upstream's flake leaves the aarch64-linux node_modules hash as
      # lib.fakeHash, and that binding can't be overridden from outside, so the
      # fixed-output step is mirrored here for that system only. The hash is
      # tied to the qmd lockfile and to the bun that runs `bun install`, so it
      # needs re-pinning when either moves. Drop once upstream pins the hash.
      nodeModules = prev.stdenvNoCC.mkDerivation {
        pname = "qmd-node-modules";
        inherit (upstream) version;
        src = inputs.qmd;
        impureEnvVars = prev.lib.fetchers.proxyImpureEnvVars ++ [
          "GIT_PROXY_COMMAND"
          "SOCKS_SERVER"
        ];
        nativeBuildInputs = [ prev.bun ];
        dontConfigure = true;
        buildPhase = ''
          export HOME=$(mktemp -d)
          bun install --backend copyfile --frozen-lockfile --ignore-scripts --no-progress --production
        '';
        installPhase = ''
          mkdir -p $out
          cp -R node_modules $out/
        '';
        dontFixup = true;
        outputHash = "sha256-DGl1qSb25R2aGYK7UXFgjWUkxPpko5V92nRR3XI389c=";
        outputHashAlgo = "sha256";
        outputHashMode = "recursive";
      };
    in
    {
      qmd = upstream.overrideAttrs (
        _:
        prev.lib.optionalAttrs isAarch64Linux {
          buildPhase = ''
            export HOME=$(mktemp -d)
            cp -R ${nodeModules}/node_modules ./
            chmod -R u+w node_modules
            (cd node_modules/better-sqlite3 && node-gyp rebuild --release)
          '';
        }
        // prev.lib.optionalAttrs prev.stdenv.hostPlatform.isLinux {
          # The wrapper exports LD_LIBRARY_PATH with the Nix glibc, which breaks
          # every host binary qmd spawns on a non-NixOS host (the Lima guest is
          # Ubuntu with a newer glibc). sqlite and libstdc++ are all the native
          # modules need.
          postFixup = ''
            sed -i 's|:${prev.stdenv.cc.libc.out}/lib||' $out/bin/qmd
          '';
        }
      );
    };
in
[
  fenixOverlay
  claudeCodeOverlay
  codexCliOverlay
  vpnSliceOverlay
  yknotifyOverlay
  qmdOverlay
  stablePackagesOverlay
]
