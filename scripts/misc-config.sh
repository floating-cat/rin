#!/bin/sh

sudo pacman-key --init
sudo pacman-key --lsign-key "farseerfc@archlinux.org"
sudo pacman -S archlinuxcn-keyring

sudo sh -c 'echo "[archlinuxcn]
Server = https://repo.archlinuxcn.org/\$arch
" >> /etc/pacman.conf'

sudo cryptsetup luksChangeKey /dev/nvme0n1p2 --iter-time 1000

sudo systemctl enable --now fstrim.timer fwupd-refresh.timer systemd-oomd.service

eval "$(ssh-agent -c)"
ssh-add ~/.ssh/id_ed25519_youri </dev/null
ssh-add ~/.ssh/id_ed25519_rin </dev/null
