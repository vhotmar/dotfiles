# Simplify Dotfiles Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Consolidate 77 snowfall-lib modules into 6 explicit Nix files while preserving all functionality.

**Architecture:** Replace snowfall-lib auto-discovery with explicit flake outputs. Consolidate all home-manager modules into a single `common.nix` with platform-specific wrappers. Keep mutable-files module for dotfile symlinks.

**Tech Stack:** Nix flakes, nix-darwin, home-manager, fenix (Rust toolchain)

---

## Testing Strategy

Since this is a configuration migration, testing means:
1. **Syntax validation**: `nix flake check`
2. **Build validation**: Build without switching to verify no evaluation errors
3. **Switch validation**: Apply config and verify programs work
4. **Functional verification**: Check key programs (fish, nvim, git) work correctly

We'll test incrementally - build after each major task before proceeding.

---

### Task 1: Create Directory Structure

**Files:**
- Create: `darwin/configuration.nix` (placeholder)
- Create: `home-manager/common.nix` (placeholder)
- Create: `home-manager/darwin.nix` (placeholder)
- Create: `home-manager/linux.nix` (placeholder)
- Create: `overlays/default.nix` (placeholder)

**Step 1: Create directories and placeholder files**

```bash
mkdir -p darwin home-manager overlays
touch darwin/configuration.nix
touch home-manager/common.nix
touch home-manager/darwin.nix
touch home-manager/linux.nix
touch overlays/default.nix
```

**Step 2: Commit structure**

```bash
git add darwin home-manager overlays
git commit -m "chore: create new simplified directory structure"
```

---

### Task 2: Write Consolidated Overlays

**Files:**
- Modify: `overlays/default.nix`

**Step 1: Write consolidated overlay file**

```nix
# overlays/default.nix
{ inputs }:
let
  # Fenix overlay for Rust toolchain
  fenixOverlay = inputs.fenix.overlays.default;

  # Custom vpn-slice with newer commit
  vpnSliceOverlay = final: prev: {
    vpn-slice-vhotmar = prev.vpn-slice.overrideAttrs (_: p: {
      version = "git";
      src = prev.fetchFromGitHub {
        owner = "dlenski";
        repo = p.pname;
        rev = "4e26adbfd14de2be5e77933e96d353ea7d200107";
        sha256 = "sha256-x9Y36/wy0HhBc7tT6rG9ehGtzkoTPMj2jAOypX6yQRk";
      };
    });
  };

  # Tmux from stable channel (for darwin compatibility)
  tmuxOverlay = final: prev: {
    tmux-stable = inputs.nixpkgs-darwin-stable.legacyPackages.${prev.system}.tmux;
  };
in
[
  fenixOverlay
  vpnSliceOverlay
  tmuxOverlay
]
```

**Step 2: Commit overlay changes**

```bash
git add overlays/default.nix
git commit -m "feat: consolidate overlays into single file"
```

---

### Task 3: Write Mutable Files Module

**Files:**
- Create: `home-manager/mutable-files.nix`

**Step 1: Copy and adapt mutable-files module**

This module is complex enough to keep separate. Copy from `nix/modules/home/mutable-files/default.nix` with minimal changes:

```nix
# home-manager/mutable-files.nix
{ config, lib, pkgs, ... }:

with lib;
let
  inherit (config.lib.dag) entryAfter;
  cfg = config.home.mutableFile;

  fileType = baseDir:
    { name, config, ... }: {
      options = with types; {
        url = mkOption {
          type = str;
          description = "URL of file to fetch";
        };

        path = mkOption {
          type = str;
          default = name;
          apply = p: if hasPrefix "/" p then p else "${baseDir}/${p}";
        };

        extractPath = mkOption {
          type = nullOr str;
          default = null;
        };

        type = mkOption {
          type = enum [ "git" "fetch" "archive" ];
          default = "fetch";
        };

        extraArgs = mkOption {
          type = listOf str;
          default = [ ];
        };
      };
    };
in {
  options.home.mutableFile = mkOption (with types; {
    type = attrsOf (submodule (fileType config.home.homeDirectory));
    default = { };
  });

  config = mkIf (cfg != { }) {
    home.activation.ensureMutableFiles = let
      mutableFilesCmds = mapAttrsToList (path: value:
        let
          url = escapeShellArg value.url;
          path = escapeShellArg value.path;
          extraArgs = escapeShellArgs value.extraArgs;
        in ''
          ${optionalString (value.type == "git")
          "[ -d ${path} ] || git clone ${extraArgs} ${url} ${path}"}
          ${optionalString (value.type == "fetch")
          "[ -e ${path} ] || curl ${extraArgs} ${url} --output ${path}"}
          ${optionalString (value.type == "archive") ''
            [ -e ${path} ] || {
              filename=$(curl ${extraArgs} --output-dir /tmp --silent --show-error --write-out '%{filename_effective}' --remote-name --remote-header-name --location ${url})
              ${
                if (value.extractPath != null) then
                  ''arc extract "/tmp/$filename" ${escapeShellArg value.extractPath} ${path}''
                else
                  ''arc unarchive "/tmp/$filename" ${path}''
              }
            }
          ''}
        '') cfg;

      script = pkgs.writeShellScript "fetch-mutable-files" ''
        PATH=${makeBinPath (with pkgs; [ gnupg git openssh ])}
        ${concatStringsSep "\n" mutableFilesCmds}
      '';
    in entryAfter [ "reloadSystemd" ] (builtins.toString script);
  };
}
```

**Step 2: Commit mutable-files module**

```bash
git add home-manager/mutable-files.nix
git commit -m "feat: add mutable-files module for dotfile cloning"
```

---

### Task 4: Write home-manager/common.nix

**Files:**
- Modify: `home-manager/common.nix`

**Step 1: Write the consolidated common config**

This is the main file consolidating all 60+ home modules:

```nix
# home-manager/common.nix
{ config, pkgs, lib, ... }:

let
  dotfilesPath = "${config.home.homeDirectory}/main/dotfiles";
  mkSymlink = path: config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/.config/${path}";
in
{
  imports = [ ./mutable-files.nix ];

  home.stateVersion = "23.11";
  programs.home-manager.enable = true;

  # ══════════════════════════════════════════════════════════════════════════════
  # PACKAGES
  # ══════════════════════════════════════════════════════════════════════════════

  home.packages = with pkgs; [
    # ── Dev Languages ─────────────────────────────────────────────────────────
    go
    (python3.withPackages (ps: with ps; [ setuptools ]))
    nodejs
    zx
    bun
    (fenix.complete.withComponents [
      "cargo"
      "clippy"
      "rust-src"
      "rustc"
      "rustfmt"
    ])
    rust-analyzer-nightly

    # ── Editors & Dev Tools ───────────────────────────────────────────────────
    lua
    tree-sitter
    lazygit
    difftastic
    clang

    # ── Shell & Terminal ──────────────────────────────────────────────────────
    # (fish, starship, tmux configured via programs.* below)

    # ── File & Search ─────────────────────────────────────────────────────────
    ripgrep
    fd
    eza
    fzf
    zoxide

    # ── Data & JSON ───────────────────────────────────────────────────────────
    jq
    yq
    jless
    bat

    # ── Git ───────────────────────────────────────────────────────────────────
    gh
    jujutsu

    # ── Kubernetes & DevOps ───────────────────────────────────────────────────
    k9s
    kind
    kubectl
    fluxcd
    dive
    podman
    helm

    # ── System & Utils ────────────────────────────────────────────────────────
    procs
    dust
    grc
    entr
    gum
    cachix
    devenv

    # ── Security ──────────────────────────────────────────────────────────────
    gnupg
    python312Packages.keyring

    # ── Misc Tools ────────────────────────────────────────────────────────────
    ast-grep
    claude-code
    opencode
    github-copilot-cli
    proton-pass-cli
    jira-cli-go
  ];

  # ══════════════════════════════════════════════════════════════════════════════
  # PROGRAMS (using home-manager modules for integration)
  # ══════════════════════════════════════════════════════════════════════════════

  # ── Git ─────────────────────────────────────────────────────────────────────
  programs.git = {
    enable = true;

    userName = "Vojtech Hotmar";
    userEmail = "vojtech.hotmar@pm.me";

    signing = {
      format = "ssh";
      signByDefault = true;
      key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIkXgI1lA120aiO1HCysdk3YEihbYCKvbGpoA0etbJxu";
    };

    extraConfig = {
      init.defaultBranch = "main";
      pull.rebase = true;
      push.autoSetupRemote = true;
      core.whitespace = "trailing-space,space-before-tab";

      alias = {
        a = "add";
        d = "diff";
        dc = "diff --cached";
        ds = "diff --staged";
        s = "status --short";
        st = "status";
        co = "checkout";
        l = "log --pretty=oneline -n 20 --graph --abbrev-commit";
      };
    };
  };

  programs.difftastic = {
    enable = true;
    git.enable = true;
  };

  # ── Fish Shell ──────────────────────────────────────────────────────────────
  programs.fish = {
    enable = true;

    shellAbbrs = {
      g = "git";
      v = "nvim";
    };

    plugins = [
      { name = "grc"; src = pkgs.fishPlugins.grc.src; }
      { name = "fzf-fish"; src = pkgs.fishPlugins.fzf-fish.src; }
      { name = "forgit"; src = pkgs.fishPlugins.forgit.src; }
    ];
  };

  # ── Starship Prompt ─────────────────────────────────────────────────────────
  programs.starship.enable = true;

  # ── Neovim ──────────────────────────────────────────────────────────────────
  programs.neovim = {
    enable = true;
    vimAlias = true;
    viAlias = true;
    vimdiffAlias = true;
    defaultEditor = true;
    plugins = with pkgs.vimPlugins; [ lazy-nvim ];
    extraLuaConfig = "require('main')";
  };

  # ── Tmux ────────────────────────────────────────────────────────────────────
  programs.tmux = {
    enable = true;
    clock24 = true;
    historyLimit = 10000;
    plugins = with pkgs.tmuxPlugins; [
      vim-tmux-navigator
      catppuccin
      extrakto
    ];
    extraConfig = ''
      source-file ~/.config/tmux-extra/tmux.conf
    '';
  };

  # ── Other Programs ──────────────────────────────────────────────────────────
  programs.btop.enable = true;
  programs.zoxide.enable = true;
  programs.direnv.enable = true;
  programs.fzf.enable = true;
  programs.eza.enable = true;

  programs.yazi = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
    enableFishIntegration = true;
    enableNushellIntegration = true;
  };

  programs.rbw = {
    enable = true;
    settings = {
      email = "vojtech.hotmar@pm.me";
      pinentry = pkgs.pinentry-tty;
    };
  };

  # ══════════════════════════════════════════════════════════════════════════════
  # MUTABLE FILES (git repos to clone)
  # ══════════════════════════════════════════════════════════════════════════════

  home.mutableFile = {
    "dotfiles" = {
      url = "git+ssh://git@github.com/vhotmar/dotfiles";
      type = "git";
      path = "main/dotfiles";
    };
    "dotfiles-private" = {
      url = "git+ssh://git@github.com/vhotmar/dotfiles-private";
      type = "git";
      path = "main/dotfiles-private";
    };
  };

  # ══════════════════════════════════════════════════════════════════════════════
  # DOTFILE SYMLINKS
  # ══════════════════════════════════════════════════════════════════════════════

  xdg.configFile = {
    "nvim/lua".source = mkSymlink "nvim/lua";
    "tmux-extra".source = mkSymlink "tmux";
    "yazi".source = mkSymlink "yazi";
    "btop".source = mkSymlink "btop";
    "k9s".source = mkSymlink "k9s";
  };

  # ══════════════════════════════════════════════════════════════════════════════
  # SESSION
  # ══════════════════════════════════════════════════════════════════════════════

  home.sessionPath = [
    "$HOME/main/bin"
    "$HOME/main/dotfiles/.local/bin"
    "$HOME/main/dotfiles-private/.local/bin"
  ];
}
```

**Step 2: Commit common.nix**

```bash
git add home-manager/common.nix
git commit -m "feat: consolidate all home modules into common.nix"
```

---

### Task 5: Write home-manager/darwin.nix

**Files:**
- Modify: `home-manager/darwin.nix`

**Step 1: Write darwin-specific home config**

```nix
# home-manager/darwin.nix
{ config, pkgs, lib, ... }:

{
  imports = [ ./common.nix ];

  home.username = "vhotmar";
  home.homeDirectory = "/Users/vhotmar";

  home.packages = with pkgs; [
    # ── macOS-only packages ───────────────────────────────────────────────────
    pngpaste
    powershell
    kdoctor
    rbenv
    openconnect
    vpn-slice-vhotmar
    oauth2c
    rust-script
    rqbit
    # azure-cli  # disabled in current config
    # ollama     # disabled in current config
  ];
}
```

**Step 2: Commit darwin.nix**

```bash
git add home-manager/darwin.nix
git commit -m "feat: add darwin-specific home-manager config"
```

---

### Task 6: Write home-manager/linux.nix

**Files:**
- Modify: `home-manager/linux.nix`

**Step 1: Write linux-specific home config**

```nix
# home-manager/linux.nix
{ config, pkgs, lib, ... }:

{
  imports = [ ./common.nix ];

  home.username = "vhotmar";
  home.homeDirectory = "/home/vhotmar";

  # Linux uses fewer packages - just the common suite
  # Add linux-specific packages here as needed
  home.packages = with pkgs; [
    # ── Linux-only packages ───────────────────────────────────────────────────
  ];
}
```

**Step 2: Commit linux.nix**

```bash
git add home-manager/linux.nix
git commit -m "feat: add linux-specific home-manager config"
```

---

### Task 7: Write darwin/configuration.nix

**Files:**
- Modify: `darwin/configuration.nix`

**Step 1: Write darwin system config**

```nix
# darwin/configuration.nix
{ config, pkgs, lib, ... }:

{
  # ══════════════════════════════════════════════════════════════════════════════
  # NIX SETTINGS
  # ══════════════════════════════════════════════════════════════════════════════

  ids.gids.nixbld = 30000;

  nix = {
    enable = true;
    package = pkgs.nixVersions.latest;

    settings = {
      experimental-features = "nix-command flakes";
      trusted-users = [ "root" "vhotmar" ];
      allowed-users = [ "root" "vhotmar" ];
    };

    gc = {
      automatic = true;
      interval = { Day = 7; };
      options = "--delete-older-than 30d";
    };
  };

  # ══════════════════════════════════════════════════════════════════════════════
  # SYSTEM PACKAGES
  # ══════════════════════════════════════════════════════════════════════════════

  environment.systemPackages = with pkgs; [
    nixfmt-classic
    nix-index
    nix-prefetch-git
    gnupg
  ];

  environment.shells = with pkgs; [ bash zsh fish ];

  # ══════════════════════════════════════════════════════════════════════════════
  # FONTS
  # ══════════════════════════════════════════════════════════════════════════════

  environment.variables = {
    LOG_ICONS = "true";
  };

  fonts.packages = with pkgs; [
    jetbrains-mono
    iosevka-bin
    lato
    fira-code
    fira-code-symbols
    julia-mono
    noto-fonts
    noto-fonts-color-emoji
    nerd-fonts.fira-code
    nerd-fonts.iosevka
  ];

  # ══════════════════════════════════════════════════════════════════════════════
  # PROGRAMS
  # ══════════════════════════════════════════════════════════════════════════════

  programs.fish.enable = true;

  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };

  # ══════════════════════════════════════════════════════════════════════════════
  # SYSTEM
  # ══════════════════════════════════════════════════════════════════════════════

  system.stateVersion = 6;
  system.primaryUser = "vhotmar";
}
```

**Step 2: Commit darwin configuration**

```bash
git add darwin/configuration.nix
git commit -m "feat: add darwin system configuration"
```

---

### Task 8: Write New flake.nix

**Files:**
- Modify: `flake.nix`

**Step 1: Write simplified flake.nix**

```nix
{
  description = "vhotmar's dotfiles";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    nixpkgs-darwin-stable.url = "github:nixos/nixpkgs/nixpkgs-unstable";

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

  outputs = { self, nixpkgs, nixpkgs-darwin-stable, nix-darwin, home-manager, fenix, ... }@inputs:
  let
    mkPkgs = system: import nixpkgs {
      inherit system;
      config = {
        allowUnfree = true;
        allowBroken = true;
      };
      overlays = import ./overlays { inherit inputs; };
    };
  in {
    # ══════════════════════════════════════════════════════════════════════════
    # macOS (macbook)
    # ══════════════════════════════════════════════════════════════════════════
    darwinConfigurations."macbook" = nix-darwin.lib.darwinSystem {
      system = "aarch64-darwin";
      pkgs = mkPkgs "aarch64-darwin";
      modules = [
        ./darwin/configuration.nix
        home-manager.darwinModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.vhotmar = import ./home-manager/darwin.nix;
        }
      ];
    };

    # ══════════════════════════════════════════════════════════════════════════
    # Linux (unix-server) - standalone home-manager
    # ══════════════════════════════════════════════════════════════════════════
    homeConfigurations."vhotmar@unix-server" = home-manager.lib.homeManagerConfiguration {
      pkgs = mkPkgs "x86_64-linux";
      modules = [ ./home-manager/linux.nix ];
    };
  };
}
```

**Step 2: Commit new flake.nix**

```bash
git add flake.nix
git commit -m "feat: replace snowfall-lib with explicit flake outputs"
```

---

### Task 9: Test Darwin Build

**Step 1: Run flake check**

```bash
nix flake check
```

Expected: No errors (warnings OK)

**Step 2: Build darwin configuration (dry run)**

```bash
nix build .#darwinConfigurations.macbook.system --dry-run
```

Expected: Shows what would be built, no errors

**Step 3: Build darwin configuration**

```bash
darwin-rebuild build --flake .#macbook
```

Expected: Build completes successfully

**Step 4: Note any errors and fix**

If there are errors, they'll likely be:
- Missing packages (typos, renamed packages)
- Missing options (check home-manager docs)
- Overlay issues

Fix each error, rebuild, and repeat.

---

### Task 10: Apply Darwin Configuration

**Step 1: Switch to new configuration**

```bash
darwin-rebuild switch --flake .#macbook
```

Expected: Switch completes, shell restarts

**Step 2: Verify fish shell works**

```bash
fish -c "echo 'Fish works!'"
```

**Step 3: Verify neovim works**

```bash
nvim --version
nvim -c "echo 'Neovim works!'" -c "q"
```

**Step 4: Verify git signing works**

```bash
git config --get user.signingkey
```

**Step 5: Verify symlinks exist**

```bash
ls -la ~/.config/nvim/lua
ls -la ~/.config/yazi
ls -la ~/.config/btop
```

**Step 6: Commit successful test**

```bash
git add -A
git commit -m "test: verify darwin configuration works"
```

---

### Task 11: Clean Up Old Structure

**Files:**
- Delete: `nix/` directory
- Delete old files from git

**Step 1: Remove old nix directory**

Only do this after confirming everything works!

```bash
rm -rf nix/
```

**Step 2: Update flake.lock**

```bash
nix flake update
```

**Step 3: Final commit**

```bash
git add -A
git commit -m "chore: remove old snowfall-lib structure

BREAKING: Migrated from snowfall-lib to explicit flake structure.

Old structure (77 modules):
- nix/modules/home/*
- nix/modules/darwin/*
- nix/systems/*
- nix/homes/*
- nix/overlays/*

New structure (6 files):
- flake.nix
- darwin/configuration.nix
- home-manager/common.nix
- home-manager/darwin.nix
- home-manager/linux.nix
- overlays/default.nix"
```

---

## Rollback Plan

If something goes wrong:

1. The old config is still in git history
2. Run: `git checkout HEAD~N -- nix/ flake.nix` (where N is commits to revert)
3. Run: `darwin-rebuild switch --flake .#macbook`

---

## Verification Checklist

After migration, verify:

- [ ] `fish` shell starts correctly
- [ ] `nvim` opens and plugins load
- [ ] `git commit` works with signing
- [ ] `tmux` starts with plugins
- [ ] `yazi` file manager works
- [ ] `kubectl` / `k9s` available
- [ ] Rust toolchain works (`cargo --version`)
- [ ] Symlinked configs editable without rebuild
- [ ] `darwin-rebuild switch` completes without errors
