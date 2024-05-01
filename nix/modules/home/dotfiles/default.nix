{ lib, config, ... }:

with lib;
let cfg = config.vlib.dotfiles;
in {
  options.vlib.dotfiles = with types; {
    enable = mkEnableOption "Clone dotfiles";
    configFile = mkOption {
      type = attrsOf (str);
      description =
        "Configurations that should be redirected from the dotfiles repostory";
      default = { };
    };
  };

  config = mkIf cfg.enable {
    home.mutableFile."dotfiles" = {
      url = "git+ssh://git@github.com/vhotmar/dotfiles";
      type = "git";
      path = "main/dotfiles";
    };

    home.mutableFile."dotfiles-private" = {
      url = "git+ssh://git@github.com/vhotmar/dotfiles-private";
      type = "git";
      path = "main/dotfiles-private";

    };

    home.sessionPath = [
      "${
        config.lib.file.mkOutOfStoreSymlink
        config.home.mutableFile."dotfiles".path
      }/.local/bin"

      "${
        config.lib.file.mkOutOfStoreSymlink
        config.home.mutableFile."dotfiles-private".path
      }/.local/bin"
    ];

    xdg.configFile = mapAttrs (name: path: {
      source = "${
          config.lib.file.mkOutOfStoreSymlink
          config.home.mutableFile."dotfiles".path
        }/.config/${path}";
    }) cfg.configFile;
  };
}
