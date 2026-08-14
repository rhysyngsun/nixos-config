default:
  just --list

git-stage:
  git add .

update:
  nix flake update

update-pkgs *args='':
  nvfetcher -c nvfetcher.toml -o pkgs/_sources/ {{args}}

switch-user *args='': git-stage
  home-manager switch -b backup --flake ".#$(whoami)" {{args}}

dry-build-system *args='': git-stage
  sudo nixos-rebuild dry-build --flake ".#lilith" {{args}}

boot-system *args='': git-stage
  sudo nixos-rebuild boot --flake ".#lilith" {{args}}

switch-system *args='': git-stage
  sudo nixos-rebuild switch --flake ".#lilith" {{args}}
