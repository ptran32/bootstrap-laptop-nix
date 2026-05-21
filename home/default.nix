{ pkgs, lib, username, ... }:

{
  home.username = username;
  # home.homeDirectory is set via users.users.<name>.home in darwin/default.nix
  home.stateVersion = "24.11";

  home.packages = with pkgs;
    [
      wget
      curl
      tig
      openssh
      coreutils   # md5sum, sha1sum (replaces removed md5sha1sum)
      tree
      ranger
      yq
      minikube
      jq
      httpie
      eza
      bat   # syntax-highlighted cat (replaces removed colorcat)
      kubectx
      kubectl
      docker
      docker-compose
      python3Packages.pygments
      zsh
      tfenv   # Terraform via tfenv only (do not add pkgs.terraform — conflicts on bin/terraform)
      powerline-fonts
      nerd-fonts.meslo-lg
    ]
    ++ lib.optionals pkgs.stdenv.isLinux [
      terminator
    ];

  fonts.fontconfig.enable = true;

  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    plugins = [
      {
        name = "powerlevel10k";
        src = pkgs.zsh-powerlevel10k;
        file = "share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
      }
    ];

    oh-my-zsh = {
      enable = true;
      theme = "";
      plugins =
        (lib.optionals pkgs.stdenv.isDarwin [
          "git"
          "brew"
          "aws"
          "z"
          "docker"
          "extract"
          "colorize"
          "virtualenv"
          "copyfile"
          "copypath"   # replaces removed copydir (copy dir/file path to clipboard)
          "kubectl"
        ])
        ++ (lib.optionals pkgs.stdenv.isLinux [
          "git"
          "vagrant"
          "aws"
          "z"
          "take"
          "docker"
        ]);
    };

    shellAliases = {
      v = "vim";
      c = "bat --paging=never";
      r = "ranger";
      l = "eza --all --modified";
      tree = "eza -T";
      kx = "kubectx";
      ks = "kubens";
      d = "docker";
      k = "kubectl";
      # zsh_reload plugin removed from Oh My Zsh; use omz reload (keep src alias)
      src = "omz reload";
    };

    initContent =
      ''
        export VISUAL=vim
        export EDITOR="$VISUAL"
        export TERM="xterm-256color"
        DEFAULT_USER=''${USER}

        POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(context dir vcs)
        POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(kubecontext virtualenv)
      ''
      + ''
        if command -v tfenv >/dev/null 2>&1; then
          eval "$(tfenv init -)"
        fi
      '';
  };

  programs.git.enable = true;

  programs.vim = {
    enable = true;
    defaultEditor = true;
    plugins = with pkgs.vimPlugins; [
      vim-fugitive
      gruvbox-community
    ];
    extraConfig = builtins.readFile ./vimrc;
  };
}
