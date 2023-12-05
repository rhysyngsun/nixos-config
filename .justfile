default:
  just --list

git-stage:
  git add .

build-user: git-stage
  home-manager switch --flake ".#$(whoami)" $@

build-system: git-stage
  sudo nixos-rebuild switch --flake ".#morrigan" $@
