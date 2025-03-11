{
  config = {
    nixpkgs.hostPlatform = "x86_64-linux";
    system-manager.allowAnyDistro = true;

    environment = {
      etc = {
        "sysctl.d/99-quic.conf".text = ''
          net.core.rmem_max = 7500000
          net.core.wmem_max = 7500000
        '';
        "sysctl.d/98-idea.conf".text = ''
          fs.inotify.max_user_watches = 2524288
          kernel.perf_event_paranoid = 1
        '';
        "udev/rules.d/99-vial.rules".text = ''
          KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{serial}=="*vial:f64c2b3c*", MODE="0660", GROUP="users", TAG+="uaccess", TAG+="udev-acl"
        '';
      };
    };
  };
}
