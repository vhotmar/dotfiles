# Simplify Dotfiles Configuration

## Goal

Consolidate 77 snowfall-lib modules into ~6 explicit Nix files while keeping:
- Platform separation (darwin / linux)
- Shared home-manager config
- Symlinked dotfiles (edit without rebuild)

## New Structure

```
dotfiles/
├── flake.nix                      # Single entry point, no snowfall-lib
├── darwin/
│   └── configuration.nix          # nix-darwin system config
├── home-manager/
│   ├── common.nix                 # All shared packages & config
│   ├── darwin.nix                 # Imports common + macOS-specific
│   └── linux.nix                  # Imports common + Linux-specific
├── overlays/
│   └── default.nix                # Consolidated overlays
└── .config/                       # Actual dotfiles (symlinked)
```

## What Gets Deleted

- `nix/modules/` (all 77 modules)
- `nix/homes/` (replaced by home-manager/)
- `nix/systems/` (replaced by darwin/)
- snowfall-lib dependency from flake inputs

## flake.nix

```nix
{
  description = "vhotmar's dotfiles";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    nix-darwin = {
      url = "github:lnl7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nix-darwin, home-manager, fenix, ... }@inputs:
  let
    mkPkgs = system: import nixpkgs {
      inherit system;
      config.allowUnfree = true;
      overlays = [
        fenix.overlays.default
        (import ./overlays)
      ];
    };
  in {
    darwinConfigurations."macbook" = nix-darwin.lib.darwinSystem {
      system = "aarch64-darwin";
      pkgs = mkPkgs "aarch64-darwin";
      modules = [
        ./darwin/configuration.nix
        home-manager.darwinModules.home-manager {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.vhotmar = import ./home-manager/darwin.nix;
        }
      ];
    };

    homeConfigurations."vhotmar@unix-server" = home-manager.lib.homeManagerConfiguration {
      pkgs = mkPkgs "x86_64-linux";
      modules = [ ./home-manager/linux.nix ];
    };
  };
}
```

## home-manager/common.nix

Single file with all packages grouped by comments:

```nix
{ config, pkgs, lib, ... }:

{
  home.stateVersion = "24.05";
  programs.home-manager.enable = true;

  home.packages = with pkgs; [
    # ── Dev Languages ─────────────────────────────────────────────
    go python3 nodejs bun rustup

    # ── Editors & Dev Tools ───────────────────────────────────────
    neovim tree-sitter lazygit difftastic

    # ── Shell & Terminal ──────────────────────────────────────────
    fish starship tmux zellij

    # ── File & Search ─────────────────────────────────────────────
    ripgrep fd eza fzf yazi zoxide

    # ── Data & JSON ───────────────────────────────────────────────
    jq yq jless

    # ── Git ───────────────────────────────────────────────────────
    gh git jujutsu

    # ── Kubernetes & DevOps ───────────────────────────────────────
    kubectl k9s kind fluxcd dive podman

    # ── Cloud ─────────────────────────────────────────────────────
    azure-cli

    # ── System & Utils ────────────────────────────────────────────
    btop procs dust grc direnv entr

    # ── Security ──────────────────────────────────────────────────
    gnupg rbw
  ];

  # Programs with useful home-manager integration
  programs.git = { enable = true; /* config */ };
  programs.fish = { enable = true; /* config */ };
  programs.starship.enable = true;
  programs.zoxide.enable = true;
  programs.direnv.enable = true;
  programs.fzf.enable = true;

  # Dotfile symlinks
  xdg.configFile = {
    "nvim".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/main/dotfiles/.config/nvim";
    "yazi".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/main/dotfiles/.config/yazi";
    "btop".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/main/dotfiles/.config/btop";
  };
}
```

## home-manager/darwin.nix

```nix
{ config, pkgs, lib, ... }:

{
  imports = [ ./common.nix ];

  home.username = "vhotmar";
  home.homeDirectory = "/Users/vhotmar";

  home.packages = with pkgs; [
    # macOS-only packages
  ];
}
```

## home-manager/linux.nix

```nix
{ config, pkgs, lib, ... }:

{
  imports = [ ./common.nix ];

  home.username = "vhotmar";
  home.homeDirectory = "/home/vhotmar";

  home.packages = with pkgs; [
    # Linux-only packages
  ];
}
```

## darwin/configuration.nix

```nix
{ config, pkgs, lib, ... }:

{
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  fonts.packages = with pkgs; [
    (nerdfonts.override { fonts = [ "JetBrainsMono" "FiraCode" ]; })
  ];

  system.defaults = {
    dock.autohide = true;
    finder.FXPreferredViewStyle = "clmv";
  };

  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };

  system.stateVersion = 4;
}
```

## Migration Steps

1. Create new directory structure
2. Write new flake.nix (remove snowfall-lib)
3. Consolidate all home modules into common.nix
4. Extract darwin-specific to darwin.nix
5. Extract linux-specific to linux.nix
6. Write darwin/configuration.nix from existing darwin modules
7. Consolidate overlays
8. Test darwin build: `darwin-rebuild switch --flake .#macbook`
9. Test linux build: `home-manager switch --flake .#vhotmar@unix-server`
10. Delete old nix/modules, nix/homes, nix/systems directories
