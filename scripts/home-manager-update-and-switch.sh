#!/bin/sh

nix run home-manager/master -- --extra-experimental-features "nix-command flakes" switch
