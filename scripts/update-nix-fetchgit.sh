#!/bin/sh

readonly home_manager_folder=$(dirname "$(dirname "$0")")
readonly pwd="$PWD"
cd "$home_manager_folder" || exit 1
eval "$(direnv export bash)"
update-nix-fetchgit home.nix
cd "$pwd" || exit
