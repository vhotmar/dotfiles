{ ... }:

{
  homebrew.casks = [
    "keepassxc"
  ];

  local.brave.extensions = {
    # KeePassXC-Browser
    "oboonakemofpalcgghocfoadofidjkkk" = {
      installation_mode = "normal_installed";
      update_url = "https://clients2.google.com/service/update2/crx";
    };
  };
}
