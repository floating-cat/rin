{
  config = {
    nixpkgs.hostPlatform = "x86_64-linux";
    system-manager.allowAnyDistro = true;

    environment = {
      etc = {
        "sysctl.d/99-idea.conf".text = ''
          fs.inotify.max_user_watches = 2524288
        '';
      };
    };

    systemd.services.nix-daemon.environment = {
      http_proxy = "http://127.0.0.1:1080";
      https_proxy = "http://127.0.0.1:1080";
      all_proxy = "http://127.0.0.1:1080";
    };
  };
}
