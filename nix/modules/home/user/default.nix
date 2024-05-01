{ lib, config, pkgs, ... }:
let
  cfg = config.vlib.user;

  homeDirectory = if cfg.name == null then
    null
  else if pkgs.stdenv.isDarwin then
    "/Users/${cfg.name}"
  else
    "/home/${cfg.name}";
in {
  options.vlib.user = {
    enable = lib.mkEnableOption "user account";

    name = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = config.snowfallorg.user.name or "vhotmar";
      description = "The user account.";
    };

    fullName = lib.mkOption {
      type = lib.types.str;
      default = "Vojtech Hotmar";
      description = "The full name of the user.";

    };

    email = lib.mkOption {
      type = lib.types.str;
      default = "vojta.hotmar@gmail.com";
      description = "The email of the user.";
    };

    home = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = homeDirectory;
      description = "The user's home directory.";
    };
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [{
    assertions = [
      {
        assertion = cfg.name != null;
        message = "vlib.user.name must be set";
      }
      {
        assertion = cfg.home != null;
        message = "vlib.user.home must be set";
      }
    ];

    home = {
      username = lib.mkDefault cfg.name;
      homeDirectory = lib.mkDefault cfg.home;
    };
  }]);
}
