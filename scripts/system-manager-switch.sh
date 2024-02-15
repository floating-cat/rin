#!/bin/sh

readonly home_manager_folder=$(dirname "$(dirname "$0")")
sudo nix run 'github:numtide/system-manager' --extra-experimental-features "nix-command flakes" -- switch --flake "$home_manager_folder"
