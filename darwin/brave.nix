{ pkgs, lib, ... }:

let
  # Brave / Chromium enterprise policies.
  bravePolicy = {
    BraveAIChatEnabled = false;

    BraveWalletDisabled = true;

    BraveRewardsDisabled = true;

    BraveVPNDisabled = true;

    TorDisabled = true;

    # telemetry / analytics
    BraveP3AEnabled = false; # privacy-preserving analytics ping
    BraveStatsPingEnabled = false; # usage ping
    MetricsReportingEnabled = false; # Chromium metrics/crash reporting
  };

  bravePolicyPlist = pkgs.writeText "com.brave.Browser.plist" (
    lib.generators.toPlist { escape = true; } bravePolicy
  );

  managedPath = "/Library/Managed Preferences/com.brave.Browser.plist";

  installScript = ''
    /bin/mkdir -p "/Library/Managed Preferences"
    if ! /usr/bin/cmp -s "${bravePolicyPlist}" "${managedPath}"; then
      /bin/cp -f "${bravePolicyPlist}" "${managedPath}"
      /bin/chmod 644 "${managedPath}"
      /usr/bin/killall cfprefsd 2>/dev/null || true
    fi
  '';
in
{
  homebrew.casks = [ "brave-browser" ];

  system.activationScripts.extraActivation.text = lib.mkAfter ''
    echo "configuring Brave managed policy..." >&2
    ${installScript}
  '';

  launchd.daemons.brave-managed-policy = {
    serviceConfig = {
      Label = "org.nixos.brave-managed-policy";
      RunAtLoad = true;
      WatchPaths = [
        "/Library/Managed Preferences"
        managedPath
      ];
      StandardOutPath = "/var/log/brave-managed-policy.log";
      StandardErrorPath = "/var/log/brave-managed-policy.log";
    };
    script = installScript;
  };
}
