#!/bin/sh

readonly home_manager_folder=$(dirname "$(dirname "$0")")
nix flake update --flake "$home_manager_folder"
./home-manager-switch.sh
