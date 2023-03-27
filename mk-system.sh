#!/bin/sh

# stage everything
git update-index --assume-unchanged nixos/hardware-configuration.nix
git add .

sudo nixos-rebuild switch --flake ".#$(hostname)" $@