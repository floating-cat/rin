#!/bin/sh

readonly home_manager_folder=$(dirname "$(dirname "$0")")
nix run home-manager/master -- switch -b backup
