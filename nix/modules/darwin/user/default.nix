{ lib, ... }:

with lib; {
  options.vlib.user = with types; {
    name = mkOption {
      type = str;
      default = "vhotmar";
      description = "The user account.";
    };

    fullName = {
      type = str;
      default = "Vojtech Hotmar";
      description = "The full name of the user.";
    };

    email = {
      type = str;
      default = "vojtech.hotmar@pm.me";
      description = "The email of the user.";
    };
  };

  config = { };
}
