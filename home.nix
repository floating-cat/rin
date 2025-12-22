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
  home.stateVersion = "25.11";

  home.packages = with pkgs; [
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
      QT_IM_MODULES="wayland;fcitx;ibus"
      XMODIFIERS=@im=fcitx

      GTK_USE_PORTAL=1
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
    "${config.xdg.configHome}/metapac/groups/all.toml".source = ./archlinux_system_packages.toml;
    "${config.xdg.configHome}/metapac/config.toml".text = ''
      enabled_backends = ["arch"]
      [arch]
      package_manager = "paru"
    '';

    "${config.xdg.configHome}/vim/helix.vim".source = builtins.fetchurl {
      url = "https://raw.githubusercontent.com/chtenb/helix.vim/main/helix.vim";
      sha256 = "1zn6z9wy291mkvhxng347mah8r7r2ff3c3c46nl8mrfg5p74zgp1";
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
    sessionVariables = {
      STARSHIP_LOG = "error";
    };
    shellAliases = {
      cat = "bat";
    };
  };

  programs = {
    ghostty = {
      enable = true;
      package = null;
      settings = {
        theme = "Red Alert";
        confirm-close-surface = false;
        keybind = [
          "performable:ctrl+c=copy_to_clipboard"
          "ctrl+v=paste_from_clipboard"
        ];
        app-notifications = "no-clipboard-copy";
      };
      systemd.enable = false;
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
        theme.name = "my-theme";
        prefers_reduced_motion = true;
        # solve https://github.com/atuinsh/atuin/issues/2522
        inline_height = 0;
      };
      themes.my-theme = {
        theme.name = "My Theme";
        colors = {
          Annotation = "white";
        };
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
    inputs.sops-nix.homeModules.sops
    inputs.plasma-manager.homeModules.plasma-manager
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
      "ssh_keys/dmit_pro_vps" = {
        path = "${config.home.homeDirectory}/.ssh/dmit_pro_vps";
      };
      "ssh_keys/config" = {
        path = "${config.home.homeDirectory}/.ssh/config";
      };

      "git_config" = {
        path = "${config.xdg.configHome}/git/config";
      };
    };
  };

  # soft linked rime config files don't work for some reason so manually copy it as a workaround
  home.activation.copyRimeIceCustomFile = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    cp -f "${config.xdg.configHome}/home-manager/rime/default.custom.yaml" "${config.xdg.dataHome}/fcitx5/rime/default.custom.yaml"
    cp -f "${config.xdg.configHome}/home-manager/rime/rime_ice.custom.yaml" "${config.xdg.dataHome}/fcitx5/rime/rime_ice.custom.yaml"
'';

  programs.plasma = mkIf isLinux {
    enable = true;
    configFile = {
      "kdeglobals"."KDE"."SingleClick" = true;
      "kwinrc"."Wayland"."InputMethod[$e]" = "/usr/share/applications/org.fcitx.Fcitx5.desktop";
    };
    shortcuts = {
      "services.org.kde.spectacle.desktop" = {
        ActiveWindowScreenShot = [ ];
        FullScreenScreenShot = [ ];
        RecordRegion = "Alt+Print";
        RecordScreen = [ ];
        RecordWindow = [ ];
        RectangularRegionScreenShot = "Print";
        WindowUnderCursorScreenShot = [ ];
        _launch = "Ctrl+Print";
      };
    };
    powerdevil.AC = {
      autoSuspend = {
        action = "nothing";
      };
    };
  };

  nix.package = pkgs.nix;
  nix.extraOptions = ''
    experimental-features = nix-command flakes
    max-jobs = auto
  '';
  news.display = "silent";

  programs.home-manager.enable = true;
}
