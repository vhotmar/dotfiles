# home-manager/common.nix
{
  config,
  pkgs,
  lib,
  ...
}:

let
  # User info - used in multiple places
  userFullName = "Vojtech Hotmar";
  userEmail = "vojtech.hotmar@pm.me";
  signingKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIkXgI1lA120aiO1HCysdk3YEihbYCKvbGpoA0etbJxu";

  # Lazy symlink helpers - only evaluated when used in config section
  dotfilesPath = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/main/dotfiles";
  dotfilesPrivatePath = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/main/dotfiles-private";
  mkSymlink =
    path:
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/main/dotfiles/.config/${path}";
in
{
  imports = [
    ./mutable-files.nix
    ./gpg.nix
  ];

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
    deno
    bun
    (fenix.complete.withComponents [
      "cargo"
      "clippy"
      "rust-analyzer"
      "rust-src"
      "rustc"
      "rustfmt"
    ])
    jbang
    uv

    # ── Editors & Dev Tools ───────────────────────────────────────────────────
    lua
    tree-sitter
    lazygit
    difftastic
    clang
    statix

    # ── Shell & Terminal ──────────────────────────────────────────────────────
    # (fish, starship, tmux configured via programs.* below)
    sesh

    # ── File & Search ─────────────────────────────────────────────────────────
    fd
    zoxide

    # ── Data & JSON ───────────────────────────────────────────────────────────
    jq
    yq-go
    jless
    csvtool

    # ── Git ───────────────────────────────────────────────────────────────────
    jujutsu

    # ── Kubernetes & DevOps ───────────────────────────────────────────────────
    k9s
    kind
    kubectl
    fluxcd
    dive
    podman
    kubernetes-helm

    # ── System & Utils ────────────────────────────────────────────────────────
    procs
    dust
    grc
    entr
    gum
    cachix
    devenv
    nmap
    parallel-full
    unzip
    socat
    gnused

    # ── Security ──────────────────────────────────────────────────────────────
    gnupg
    python312Packages.keyring
    openssh
    libfido2
    yubikey-manager

    # ── Misc Tools ────────────────────────────────────────────────────────────
    ast-grep
    claude-code
    opencode
    github-copilot-cli
    proton-pass-cli
    jira-cli-go
    sshpass
  ];

  # ══════════════════════════════════════════════════════════════════════════════
  # PROGRAMS (using home-manager modules for integration)
  # ══════════════════════════════════════════════════════════════════════════════

  # ── Git ─────────────────────────────────────────────────────────────────────
  programs.git = {
    enable = true;

    signing = {
      format = "ssh";
      signByDefault = true;
      key = signingKey;
    };

    settings = {
      user = {
        name = userFullName;
        email = userEmail;
      };

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

    # Auto-attach (or create) the "general" tmux session for interactive,
    # non-tmux, local shells. No `exec`, so detaching with prefix-d drops
    # back to a fish prompt instead of closing the terminal.
    interactiveShellInit = ''
      if status is-interactive
         and not set -q TMUX
         and not set -q SSH_TTY
          tmux new-session -A -s general
      end
    '';

    shellAbbrs = {
      g = "git";
      v = "nvim";

      l = "eza -al";
      ls = "eza -l";
      la = "eza -al";
      ll = "eza -l";
      lL = "eza -algiSH --git";
      lt = "eza -lT";
    };

    plugins = [
      {
        name = "grc";
        src = pkgs.fishPlugins.grc.src;
      }
      {
        name = "fzf-fish";
        src = pkgs.fishPlugins.fzf-fish.src;
      }
      {
        name = "forgit";
        src = pkgs.fishPlugins.forgit.src;
      }
    ];
  };

  # ── Starship Prompt ─────────────────────────────────────────────────────────
  programs.starship = {
    enable = true;

    settings = {
      palette = "catppuccin_frappe";
    }
    // builtins.fromTOML (builtins.readFile ./nerd-font.toml)
    // builtins.fromTOML (builtins.readFile ./prompt.toml)
    // builtins.fromTOML (
      builtins.readFile (
        pkgs.fetchFromGitHub {
          owner = "catppuccin";
          repo = "starship";
          rev = "5629d23";
          sha256 = "nsRuxQFKbQkyEI4TXgvAjcroVdG+heKX5Pauq/4Ota0=";
        }
        + /palettes/frappe.toml
      )
    );
  };

  # ── Neovim ──────────────────────────────────────────────────────────────────
  programs.neovim = {
    enable = true;
    vimAlias = true;
    viAlias = true;
    vimdiffAlias = true;
    defaultEditor = true;
    plugins = with pkgs.vimPlugins; [ lazy-nvim ];
    initLua = "require('main')";
    withRuby = true;
    withPython3 = true;
  };

  # ── Tmux ────────────────────────────────────────────────────────────────────
  programs.tmux = {
    enable = true;
    shell = "${pkgs.fish}/bin/fish";
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
  programs.zoxide = {
    enable = true;
    enableFishIntegration = true;
  };
  programs.direnv = {
    enable = true;
    nix-direnv = {
      enable = true;
    };
  };
  programs.fzf = {
    enable = true;

    # https://github.com/catppuccin/fzf

    # Catpuccin Frappe
    colors = {
      "bg+" = "#414559";
      bg = "#303446";
      spinner = "#f2d5cf";
      hl = "#e78284";
      fg = "#c6d0f5";
      header = "#e78284";
      info = "#ca9ee6";
      pointer = "#f2d5cf";
      marker = "#f2d5cf";
      "fg+" = "#c6d0f5";
      prompt = "#ca9ee6";
      "hl+" = "#e78284";
      "selected-bg" = "#51576d";
      "border" = "#414559";
      "label" = "#c6d0f5";
    };

    defaultOptions = [
      "--ansi"
      "--no-separator"
    ];

    fileWidgetOptions = [
      # Preview the contents of the selected file
      "--walker-skip .git,node_modules,target"
      "--preview 'bat --color=always --plain {}'"
      "--bind 'ctrl-/:change-preview-window(down|hidden|)'"
    ];

    changeDirWidgetOptions = [
      # Preview the contents of the selected directory
      "--walker-skip .git,node_modules,target"
      "--preview 'eza -l --tree --level=2 --color=always {}'"
    ];

    historyWidgetOptions = [
      "--preview 'echo {}' --preview-window up:3:hidden:wrap"
      "--bind 'ctrl-/:toggle-preview'"
      "--bind 'ctrl-y:execute-silent(echo -n {2..} | pbcopy)+abort'"
      "--color header:italic"
      "--header 'Press CTRL-Y to copy command into clipboard'"
    ];
  };
  programs.eza.enable = true;

  programs.yazi = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
    enableFishIntegration = true;
    shellWrapperName = "y";
  };

  programs.rbw = {
    enable = true;
    settings = {
      email = userEmail;
      pinentry = pkgs.pinentry-tty;
    };
  };

  programs.bat.enable = true;
  programs.gh.enable = true;
  programs.gh-dash.enable = true;
  programs.ripgrep = {
    enable = true;
    arguments = [ "--ignore-case" ];
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
    "sesh".source = mkSymlink "sesh";
    "zellij".source = mkSymlink "zellij";
    "bat".source = mkSymlink "bat";
    "lazygit".source = mkSymlink "lazygit";
    "doom".source = mkSymlink "doom";
  };

  # ══════════════════════════════════════════════════════════════════════════════
  # SESSION
  # ══════════════════════════════════════════════════════════════════════════════

  home.sessionPath = [
    "$HOME/main/bin"
    "${dotfilesPath}/.local/bin"
    "${dotfilesPrivatePath}/.local/bin"
  ];
}
