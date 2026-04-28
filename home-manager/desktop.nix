# home-manager/desktop.nix
# Display-dependent config. Imported only on hosts with a GUI (i.e. not
# headless servers or Lima VMs).
{
  config,
  pkgs,
  lib,
  ...
}:

let
  mkSymlink =
    path:
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/main/dotfiles/.config/${path}";

  # ── App-bundle plumbing for Alfred-launchable Alacritty wrappers ───────────
  # mac-app-util (loaded at the flake level) makes Nix-installed .apps
  # discoverable by LaunchServices/Spotlight/Alfred. The custom bundles below
  # exist so Alfred has a per-variant icon to render in the Dock.

  alacrittyLogoSvg = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/alacritty/alacritty/v0.17.0/extra/logo/alacritty-term.svg";
    sha256 = "1nzxkadvkwmb4pk0pidwkaccp3ba5pffpz05d17imy36qyll6zv4";
  };

  svgToPng =
    {
      name,
      svg,
      substitutions ? [ ],
    }:
    pkgs.runCommand "${name}.png" { nativeBuildInputs = [ pkgs.librsvg ]; } ''
      cp ${svg} src.svg
      ${lib.concatMapStringsSep "\n" (
        { from, to }: ''sed -i "s|${from}|${to}|gI" src.svg''
      ) substitutions}
      rsvg-convert -w 1024 -h 1024 src.svg -o "$out"
    '';

  # Use macOS-native iconutil + imagemagick to produce a canonical .icns layout
  # (Apple's preferred sizes + @2x variants). libicns/png2icns produced an icon
  # whose "is32" 16x16 entry came first, which Spotlight/Alfred render fine for
  # large surfaces (Dock, Cmd-Tab) but incorrectly for small ones.
  pngToIcns =
    name: png:
    pkgs.runCommand "${name}.icns" { nativeBuildInputs = [ pkgs.imagemagick ]; } ''
      iconset="$(mktemp -d)/icon.iconset"
      mkdir -p "$iconset"
      for size in 16 32 128 256 512; do
        double=$((size * 2))
        magick ${png} -resize ''${size}x''${size}     "$iconset/icon_''${size}x''${size}.png"
        magick ${png} -resize ''${double}x''${double} "$iconset/icon_''${size}x''${size}@2x.png"
      done
      /usr/bin/iconutil -c icns "$iconset" -o "$out"
    '';

  mkAppBundle =
    {
      name,
      slug,
      bundleId,
      icon,
      command,
    }:
    let
      icns = pngToIcns slug icon;
    in
    pkgs.runCommand "${slug}-app" { } ''
      app="$out/Applications/${name}.app"
      mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"
      cp ${icns} "$app/Contents/Resources/icon.icns"
      cat > "$app/Contents/Info.plist" <<'PLISTEOF'
      <?xml version="1.0" encoding="UTF-8"?>
      <plist version="1.0"><dict>
        <key>CFBundleName</key><string>${name}</string>
        <key>CFBundleDisplayName</key><string>${name}</string>
        <key>CFBundleIdentifier</key><string>${bundleId}</string>
        <key>CFBundleExecutable</key><string>run</string>
        <key>CFBundleIconFile</key><string>icon</string>
        <key>CFBundlePackageType</key><string>APPL</string>
        <key>CFBundleVersion</key><string>1</string>
        <key>CFBundleShortVersionString</key><string>1.0</string>
        <key>LSUIElement</key><false/>
      </dict></plist>
      PLISTEOF
      cat > "$app/Contents/MacOS/run" <<'RUNEOF'
      #!${pkgs.bash}/bin/bash
      ${command}
      RUNEOF
      chmod +x "$app/Contents/MacOS/run"
    '';

  alacrittyPng = svgToPng {
    name = "alacritty-icon";
    svg = alacrittyLogoSvg;
  };

  # Catppuccin Mocha tint — matches the colorscheme used inside the kdev terminal.
  alacrittyKdevPng = svgToPng {
    name = "alacritty-kdev-icon";
    svg = alacrittyLogoSvg;
    substitutions = [
      { from = "#ec2802"; to = "#cba6f7"; } # flame start  -> Mocha mauve
      { from = "#fcb200"; to = "#b4befe"; } # flame end    -> Mocha lavender
      { from = "#14232b"; to = "#1e1e2e"; } # term body    -> Mocha base
      { from = "#069efe"; to = "#89b4fa"; } # accent       -> Mocha blue
    ];
  };

  alacrittyBin = "${pkgs.alacritty}/Applications/Alacritty.app/Contents/MacOS/alacritty";

  # Spotlight/Alfred launch via mac-app-util's AppleScript trampoline, which
  # inherits launchd's minimal PATH (/usr/bin:/bin:...). alacritty's
  # `program = "fish"` config relies on PATH lookup, so it can't find the
  # shell and exits silently. Inject the user's profile dirs the same way
  # `.local/bin/alacritty-kdev` does.
  alacrittyLocal = mkAppBundle {
    name = "Alacritty Local";
    slug = "alacritty-local";
    bundleId = "local.vhotmar.alacritty";
    icon = alacrittyPng;
    command = ''
      export PATH="/etc/profiles/per-user/${config.home.username}/bin:/run/current-system/sw/bin:$PATH"
      exec ${alacrittyBin} --working-directory "$HOME" "$@"
    '';
  };

  alacrittyKdev = mkAppBundle {
    name = "Alacritty Kdev";
    slug = "alacritty-kdev";
    bundleId = "local.vhotmar.alacritty-kdev";
    icon = alacrittyKdevPng;
    command = ''exec "${config.home.homeDirectory}/main/dotfiles/.local/bin/alacritty-kdev" "$@"'';
  };
in
{
  home.packages = with pkgs; [
    ueberzugpp

    # Thin wrapper so `alacritty-kdev` is on PATH for non-login-shell
    # callers (Alfred, launchd, etc). The real script stays in
    # .local/bin so edits don't require a home-manager rebuild.
    (writeShellScriptBin "alacritty-kdev" ''
      exec "${config.home.homeDirectory}/main/dotfiles/.local/bin/alacritty-kdev" "$@"
    '')

    alacrittyLocal
    alacrittyKdev
  ];

  programs.alacritty.enable = true;

  xdg.configFile."alacritty".source = mkSymlink "alacritty";
}
