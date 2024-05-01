{ pkgs, ... }:

{
    packages = with pkgs; [ stylua ];
    languages.lua.enable = true;
}
