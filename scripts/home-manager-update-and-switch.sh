#!/bin/sh

readonly home_manager_folder=$(dirname "$(dirname "$0")")
nix --experimental-features 'nix-command flakes' flake update --flake "$home_manager_folder"
nix run home-manager/master -- switch -b backup
