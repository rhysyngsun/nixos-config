@default:
  just --list

@git-stage:
  git add .

@switch-user *args='': git-stage
  home-manager switch --flake ".#$(whoami)" $@

@boot-system *args='': git-stage
  sudo nixos-rebuild boot --flake ".#morrigan" $@

@switch-system *args='': git-stage
  sudo nixos-rebuild switch --flake ".#morrigan" $@
