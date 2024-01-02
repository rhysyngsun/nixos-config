default:
  just --list

git-stage:
  git add .

switch-user *args='': git-stage
  home-manager switch --flake ".#$(whoami)" {{args}}

dry-build-system *args='': git-stage
  sudo nixos-rebuild dry-build --flake ".#morrigan" {{args}}

boot-system *args='': git-stage
  sudo nixos-rebuild boot --flake ".#morrigan" {{args}}

switch-system *args='': git-stage
  sudo nixos-rebuild switch --flake ".#morrigan" {{args}}
