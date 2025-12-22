#!/bin/sh

sudo sh -c 'echo "[archlinuxcn]
Server = https://repo.archlinuxcn.org/\$arch
" >> /etc/pacman.conf'

sudo gpasswd -a username nix-users
sudo systemctl enable --now nix-daemon.service
mkdir -p ~/.config/nix/
echo "experimental-features = nix-command flakes" > ~/.config/nix/nix.conf

sudo cryptsetup luksChangeKey /dev/nvme0n1p2 --iter-time 1000
sudo systemctl enable --now fwupd-refresh.timer systemd-oomd.service

atuin import auto

eval "$(ssh-agent -c)"
ssh-add ~/.ssh/id_ed25519 </dev/null
ssh-add ~/.ssh/id_ed25519_rin </dev/null

distrobox create --name arch --image quay.io/toolbx-images/archlinux-toolbox:latest --home ~/Soft/container --volume /etc/pacman.d/:/etc/pacman.d

# use PKGEXT='.pkg.tar' in /etc/makepkg.conf

# for distrobox
sudo pacman -S gtk3 gnome-keyring seahorse helix
distrobox-export -a jetbrains-toolbox
distrobox-export -a yourkit

alias git='/usr/bin/distrobox-host-exec /usr/bin/git'
funcsave git

# for intellij idea
echo "[Desktop Entry]
Name=Dolphin
Exec=dolphin %u
" >> ~/.local/share/applications/dolphin.desktop
sudo ln -s /usr/bin/distrobox-host-exec /usr/bin/dolphin
paru qt6-base # needed for xdg-mime command
set PATH $PATH:/usr/lib/qt6/bin/
xdg-mime default dolphin.desktop inode/directory

systemctl enable --user app-com.mitchellh.ghostty.service

# for Nix: https://wiki.archlinux.org/title/Nix#Configuration
nix-channel --add https://nixos.org/channels/nixpkgs-unstable
nix-channel --update
