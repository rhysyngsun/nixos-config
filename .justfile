default:
  just --list

git-stage:
  git add .

update:
  nix flake update

update-pkgs *args='':
  nvfetcher -c nvfetcher.toml -o pkgs/_sources/ {{args}}
  just refresh-hashes

# nvfetcher pins `src`, but it cannot compute hashes that are only knowable
# after a fetch. Go is the case here: `vendorHash` is a fixed-output hash over
# the whole module cache, and nvfetcher has no Go counterpart to the
# `cargo_lock` extraction that spares lean-ctx a `cargoHash`. So dagger's hash
# is rederived here instead, from the `src` nvfetcher just repinned.
#
# `--version skip` because nvfetcher owns the version - left to itself
# nix-update would chase the upstream tag and desync the two. `--no-src` for
# the same reason one level down: the src hash lives in the generated
# `pkgs/_sources/`, which nix-update must not touch, so refetching it is pure
# waste.
refresh-hashes:
  nix-update --flake --version skip --no-src dagger

switch-user *args='': git-stage
  home-manager switch -b backup --flake ".#$(whoami)" {{args}}

dry-build-system *args='': git-stage
  sudo nixos-rebuild dry-build --flake ".#lilith" {{args}}

boot-system *args='': git-stage
  sudo nixos-rebuild boot --flake ".#lilith" {{args}}

switch-system *args='': git-stage
  sudo nixos-rebuild switch --flake ".#lilith" {{args}}
