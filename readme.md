* Home config

** Updates

```sh
nix flake update
sudo darwin-rebuild switch --flake ~/main/dotfiles/nix#macbook # or some other path
```

** Machine-local config

`dotfiles rebuild` overrides the `local` flake input with `~/main/dotfiles-local` when that
directory has a `default.nix`. It is an ordinary home-manager module that stays out of this repo
and out of `flake.lock`; only `vhotmar@lima` imports it. Copy the directory to carry it to another
machine.
