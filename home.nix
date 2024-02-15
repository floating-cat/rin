{
  pkgs,
  inputs,
  lib,
  config,
  ...
}:

let
  inherit (pkgs.stdenv) isLinux;
  inherit (lib) mkIf;
in
{
  home.username = "username";
  home.homeDirectory = "/home/username";
  home.stateVersion = "24.05";

  home.packages = with pkgs; [
    emptyDirectory
    # # It is sometimes useful to fine-tune packages, for example, by applying
    # # overrides. You can do that directly here, just don't forget the
    # # parentheses. Maybe you want to install Nerd Fonts with a limited number of
    # # fonts?
    # (pkgs.nerdfonts.override { fonts = [ "FantasqueSansMono" ]; })

    # # You can also create simple shell scripts directly inside your
    # # configuration. For example, this adds a command 'my-hello' to your
    # # environment:
    # (pkgs.writeShellScriptBin "my-hello" ''
    #   echo "Hello, ${config.home.username}!"
    # '')
  ];

  home.file = mkIf isLinux {
    "${config.xdg.configHome}/fontconfig/fonts.conf".source = ./fonts.conf;

    ".xprofile".text = ''
      export GTK_IM_MODULE=fcitx
      export QT_IM_MODULE=fcitx
      export XMODIFIERS=@im=fcitx

      # https://gitlab.gnome.org/GNOME/gtk/-/issues/6299
      export GTK_USE_PORTAL=1
    '';
    "${config.xdg.configHome}/environment.d/envvars.conf".text = ''
      GTK_IM_MODULE=fcitx
      QT_IM_MODULE=fcitx
      XMODIFIERS=@im=fcitx

      GTK_USE_PORTAL=1
    '';
    "${config.xdg.dataHome}/fcitx5/rime/default.custom.yaml".text = ''
      patch:
        __include: rime_ice_suggestion:/
    '';
    "${config.xdg.dataHome}/fcitx5/rime/rime_ice.custom.yaml".text = ''
      patch:
        melt_eng/initial_quality: 0
    '';

    "${config.xdg.configHome}/autostart/ssh-add.desktop".text = ''
      [Desktop Entry]
      Exec=ssh-add -q .ssh/id_ed25519 .ssh/id_ed25519_rin
      Name=ssh-add
      Type=Application
    '';
    "${config.xdg.configHome}/environment.d/ssh_askpass.conf".text = ''
      [Desktop Entry]
      SSH_ASKPASS=/usr/bin/ksshaskpass
      SSH_ASKPASS_REQUIRE=prefer
    '';

    "${config.xdg.configHome}/paru/paru.conf".text = ''
      [options]
      BottomUp
    '';
    "${config.xdg.configHome}/pacdef/groups/packages.ini".source = ./archlinux_system_packages.ini;
    "${config.xdg.configHome}/pacdef/pacdef.yaml".text = ''
      disabled_backends: ["python", "rust"]
    '';

    "${config.xdg.configHome}/vim/helix.vim".source = builtins.fetchurl {
      url = "https://raw.githubusercontent.com/chtenb/helix.vim/main/helix.vim";
      sha256 = "1rygni1yc0vj9idkp4wd7pf46v8yyhbw8rxsys3f5vwa5r59agbc";
    };

    "${config.xdg.configHome}/mpv/mpv.conf".text = ''
      window-scale=0.5
      profile=high-quality
      video-sync=display-resample
      interpolation
      tscale=oversample
    '';
  };

  home = {
    sessionPath = mkIf isLinux [ "$HOME/.local/share/JetBrains/Toolbox/scripts" ];
    sessionVariables = {
      STARSHIP_LOG = "error";
    };
    shellAliases = {
      cat = "bat";
    };
  };

  programs = {
    kitty = {
      enable = true;
      package = pkgs.emptyDirectory;
      extraConfig = ''
        mouse_map right press ungrabbed no-op
        mouse_map right click ungrabbed copy_to_clipboard
      '';
      keybindings = {
        "ctrl+c" = "copy_or_interrupt";
      };
      settings = {
        confirm_os_window_close = 0;
      };
      theme = "Red Alert";
    };
    fish = {
      enable = true;
      interactiveShellInit = ''
        set fish_greeting
        fish_config theme choose Lava
      '';
    };

    helix = {
      enable = true;
      defaultEditor = true;
      extraPackages = with pkgs; [
        nil
        nixfmt-rfc-style
      ];
      languages = {
        language-server = {
          nil.config.nil = {
            formatting.command = [ "nixfmt" ];
            nix.flake.autoEvalInputs = true;
          };
        };
      };
      settings = {
        theme = "gruvbox_light";
        editor = {
          true-color = true;
        };
      };
    };

    starship = {
      enable = true;
      settings = {
        "$schema" = "https://starship.rs/config-schema.json";
        add_newline = false;
        character = {
          success_symbol = "[➜](bold green)";
          error_symbol = "[✕](bold purple)";
        };
      };
    };
    atuin = {
      enable = true;
      settings = {
        prefers_reduced_motion = true;
      };
    };
    zoxide.enable = true;
    bat = {
      enable = true;
      config = {
        theme = "ansi";
      };
    };
    ripgrep.enable = true;

    tealdeer = {
      enable = true;
      settings = {
        updates = {
          auto_update = true;
        };
      };
    };

    direnv = {
      enable = true;
      nix-direnv.enable = true;
      config = {
        global.hide_env_diff = true;
      };
    };
  };

  imports = [
    inputs.sops-nix.homeManagerModules.sops
    inputs.plasma-manager.homeManagerModules.plasma-manager
  ];
  sops = {
    defaultSopsFile = ./secrets.yaml;
    age.keyFile = "${config.xdg.configHome}/sops/age/keys.txt";

    secrets = builtins.mapAttrs (_: value: value // { mode = "0600"; }) {
      "ssh_keys/id_ed25519" = {
        path = "${config.home.homeDirectory}/.ssh/id_ed25519";
      };
      "ssh_keys/id_ed25519_rin" = {
        path = "${config.home.homeDirectory}/.ssh/id_ed25519_rin";
      };
      "ssh_keys/oracle_vps" = {
        path = "${config.home.homeDirectory}/.ssh/oracle_vps";
      };
      "ssh_keys/config" = {
        path = "${config.home.homeDirectory}/.ssh/config";
      };

      "git_config" = {
        path = "${config.xdg.configHome}/git/config";
      };
    };
  };
  # Workaround https://github.com/Mic92/sops-nix/issues/478
  home.activation.setupEtc = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    run /usr/bin/systemctl start --user sops-nix
  '';

  programs.plasma = mkIf isLinux {
    enable = true;
    shortcuts = {
      "services.org.kde.spectacle.desktop" = {
        ActiveWindowScreenShot = [ ];
        FullScreenScreenShot = [ ];
        RecordRegion = "Ctrl+Print";
        RecordScreen = [ ];
        RecordWindow = [ ];
        RectangularRegionScreenShot = "Print";
        WindowUnderCursorScreenShot = [ ];
        _launch = "Shift+Print";
      };
    };
  };

  nix.package = pkgs.nix;
  nix.extraOptions = ''
    experimental-features = nix-command flakes
    auto-optimise-store = true
    keep-outputs = true
    max-jobs = auto
  '';
  news.display = "silent";

  programs.home-manager.enable = true;
}
