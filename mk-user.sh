#!/bin/sh

# stage everything
git update-index --assume-unchanged nixos/hardware-configuration.nix
git add .

home-manager switch --flake ".#$(whoami)@$(hostname)" $@
