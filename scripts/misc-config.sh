#!/bin/sh

sudo sh -c 'echo "[archlinuxcn]
Server = https://repo.archlinuxcn.org/\$arch
" >> /etc/pacman.conf'

sudo gpasswd -a username nix-users
sudo systemctl enable --now nix-daemon.service
mkdir -p ~/.config/nix/
echo "experimental-features = nix-command flakes" > ~/.config/nix/nix.conf

sudo cryptsetup luksChangeKey /dev/nvme0n1p2 --iter-time 1000
sudo systemctl enable --now fwupd-refresh.timer systemd-oomd.service libvirtd virtlogd

atuin import auto

eval "$(ssh-agent -c)"
ssh-add ~/.ssh/id_ed25519 </dev/null
ssh-add ~/.ssh/id_ed25519_rin </dev/null

distrobox create --name arch --init --image quay.io/toolbx-images/archlinux-toolbox:latest --home ~/Soft/container --volume /etc/pacman.d/:/etc/pacman.d

# for distrobox
sudo timedatectl set-timezone Asia/Shanghai
sudo pacman -S gtk3 gnome-keyring seahorse helix
paru -S yourkit bubblejail 115pc
distrobox-export -a jetbrains-toolbox
distrobox-export -a yourkit

# use PKGEXT='.pkg.tar' in /etc/makepkg.conf
