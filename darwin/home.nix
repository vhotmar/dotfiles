{ ... }:

{
  homebrew.casks = [
    "proton-mail"
    "proton-pass"
    "claude"
    "signal"
    "spotify"
    "todoist-app"
  ];

  local.brave.extensions = {
    # Proton Pass
    "ghmbeldphafepmbegfdlkpapadhbakde" = {
      installation_mode = "normal_installed";
      update_url = "https://clients2.google.com/service/update2/crx";
    };
  };
}
