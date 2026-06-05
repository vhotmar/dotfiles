{ ... }:

{
  homebrew.casks = [ "brave-browser" ];

  system.defaults.CustomUserPreferences."com.brave.Browser" = {
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
}
