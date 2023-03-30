#!/bin/sh

# stage everything
git add .

sudo nixos-rebuild switch --flake ".#morrigan" $@