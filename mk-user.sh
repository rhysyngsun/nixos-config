#!/bin/sh

# stage everything
git add .

home-manager switch --flake ".#$(whoami)" $@