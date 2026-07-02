{ pkgs, host, ... }:

let
  inherit (host) username;

  anyconnectProxy = pkgs.writeShellScript "vpn-anyconnect-proxy" ''
    set -eu
    case "''${1:-}" in
      0 | 1) enable=$1 ;;
      *)
        echo "usage: vpn-anyconnect-proxy 0|1" >&2
        exit 2
        ;;
    esac

    SC=/usr/sbin/scutil
    KEY=State:/Network/Service/com.cisco.anyconnect/Proxies

    if ! echo "show $KEY" | "$SC" | ${pkgs.gnugrep}/bin/grep -q ProxyAutoConfigURLString; then
      echo "vpn-anyconnect-proxy: $KEY absent or has no PAC URL; skipping" >&2
      exit 0
    fi

    printf 'open\nget %s\nd.add ProxyAutoConfigEnable # %s\nset %s\n' \
      "$KEY" "$enable" "$KEY" | "$SC"
  '';
in
{
  homebrew.casks = [
    "keepassxc"
    "bruno"
  ];

  security.sudo.extraConfig = ''
    ${username} ALL=(root) NOPASSWD: ${anyconnectProxy}
  '';

  launchd.user.agents.vpn-proxy = {
    serviceConfig = {
      RunAtLoad = true;
      StartInterval = 5;
      StandardOutPath = "/tmp/vpn-proxy.out";
      StandardErrorPath = "/tmp/vpn-proxy.err";
    };
    script = ''
      PAC_FILE="$HOME/.config/vpn-proxy/pac-url"
      SERVICES="Wi-Fi
      USB 10/100/1000 LAN"

      VPN=/opt/cisco/anyconnect/bin/vpn
      NS=/usr/sbin/networksetup
      STATE_FILE=/tmp/.vpn-proxy-state

      [ -x "$VPN" ] || exit 0
      current=$("$VPN" state 2>/dev/null | ${pkgs.gnused}/bin/sed -nE '/>> state:/{s/.*>> state:[[:space:]]*([A-Za-z]+).*/\1/p;q;}')
      [ -n "$current" ] || exit 0

      last=$(cat "$STATE_FILE" 2>/dev/null || true)
      [ "$current" = "$last" ] && exit 0          # only act on a transition
      printf '%s' "$current" > "$STATE_FILE"

      apply() {
        PAC_URL=$(tr -d '[:space:]' < "$PAC_FILE" 2>/dev/null)
        if [ -z "$PAC_URL" ]; then
          echo "vpn-proxy: $PAC_FILE missing or empty; not setting proxy" >&2
          return 0
        fi
        printf '%s\n' "$SERVICES" | while IFS= read -r svc; do
          [ -n "$svc" ] && "$NS" -setautoproxyurl "$svc" "$PAC_URL"
        done
        sudo ${anyconnectProxy} 1
      }
      clear() {
        printf '%s\n' "$SERVICES" | while IFS= read -r svc; do
          [ -n "$svc" ] && "$NS" -setautoproxystate "$svc" off
        done
      }

      case "$current" in
        Connected)    apply ;;
        Disconnected) clear ;;
        *)            : ;;
      esac
    '';
  };

  local.brave.extensions = {
    # KeePassXC-Browser
    "oboonakemofpalcgghocfoadofidjkkk" = {
      installation_mode = "normal_installed";
      update_url = "https://clients2.google.com/service/update2/crx";
    };
  };
}
