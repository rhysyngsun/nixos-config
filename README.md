# nixos

Personal NixOS and home-manager configuration - one laptop, two users, everything
from the bootloader to the Neovim setup declared in this repo. It is built on
[flake-parts] and organized with the [dendritic pattern], which means the config
is arranged by *concern* rather than by machine: there is a file for git, a file
for zsh, a file for the AI tooling, and hosts pick up the ones they want.

[flake-parts]: https://flake.parts
[dendritic pattern]: https://github.com/mightyiam/dendritic

## What's in here

**`lilith`** is the only host - a Lenovo ThinkPad P1 with Intel + NVIDIA Optimus
graphics running in prime-sync mode, booting with systemd-boot. The default
session is Plasma 6 on Wayland via SDDM, with [niri] (a scrolling window manager)
also installed and selectable. Pipewire for audio, Docker, Steam, flatpak,
printing with Avahi discovery, and geoclue-driven automatic timezone.

[niri]: https://github.com/YaLTeR/niri

**Two home configurations**, `nathan` and `rhysyngsun`, run as standalone
home-manager - they are activated separately from the system, not through
`home-manager.users.*`. Each one composes the shared `programs-*` aspects plus
its own `home/<user>/home.nix`.

**Look and feel** is Catppuccin Mocha with Lavender accents, applied end to end:
Plymouth at boot, SDDM, KDE, cursors, rofi, btop. [stylix] is present with
`autoEnable = false` and currently drives only wezterm; the palette and font
definitions that everything else reads come from `pkgs.rice`, built on
[nix-rice].

[stylix]: https://github.com/danth/stylix
[nix-rice]: https://github.com/bertof/nix-rice

**Tooling**: wezterm, zsh with starship, tmux, yazi, VS Code, and Neovim
configured declaratively with [nvf] (its own `vim.*` option schema, in `nvf/`).

[nvf]: https://github.com/NotAShelf/nvf

**MIT Open Learning bits**, since this is a work machine: the MIT CA certificate
installed system-wide, `networking.extraHosts` entries for ol-infra local
development, git identity switching for `mitodl/*` remotes, and the witan MCP
server - built hermetically from agent-kit's own `uv.lock` with uv2nix - wired
into Claude Code.

## Using it

```sh
direnv allow              # or: nix develop
$EDITOR modules/...       # make a change
just dry-build-system     # check it evaluates and builds
just switch-system        # apply to the running system (needs sudo)
just switch-user          # apply the home-manager side
```

The one thing that will bite you: **`git add` new files.** Flakes only see
tracked files, so a `.nix` file you created but never staged is invisible to the
build and your change will silently do nothing. The `just` recipes run `git add
.` for you; a bare `nixos-rebuild` will not.

For maintenance, `just update` bumps the flake inputs and `just update-pkgs`
re-pins the third-party sources in `pkgs/_sources/` via nvfetcher. Run `just`
with no arguments to list everything.

## How it's organized

Every `.nix` file under `modules/` is picked up automatically - there is no list
of imports to maintain. Each file registers a module under a name, and the
configurations are *derived* from those names rather than declared anywhere:
anything called `host-<name>` becomes `nixosConfigurations.<name>`, and anything
called `home-<name>` becomes `homeConfigurations.<name>`. Nothing in `flake.nix`
enumerates hosts or users.

```
flake.nix           inputs, and the ~40 lines that derive every configuration
modules/            all auto-imported module registrations
  hosts/            host-lilith.nix   -> nixosConfigurations.lilith
  home/             home-nathan.nix   -> homeConfigurations.nathan
  programs/         reusable per-program aspects
  services/         reusable system services
  themes/           theming aspects
hosts/lilith/       machine-specific bits (hardware config, MIT hosts entries)
home/               plain home-manager modules, incl. per-user home.nix
nvf/                Neovim configuration
pkgs/               custom packages, exposed as an overlay
overlays/           the overlays applied to every configuration
themes/             stylix config and wallpapers
secrets/            sops-encrypted secrets
```

If you are editing this repo - especially with an AI agent - read
[AGENTS.md](AGENTS.md) for the exact conventions: the module file shape, how
modules reference each other, and the things that break the flake.

## Bringing it up on new hardware

There is no disko or impermanence setup here, so partitioning is manual.

1. Partition and mount the target disk, then run `nixos-generate-config` and put
   the result at `hosts/<name>/hardware-configuration.nix`.
2. Add `modules/hosts/host-<name>.nix` registering
   `flake.modules.nixos.host-<name>` and importing that hardware config -
   `modules/hosts/host-lilith.nix` is the reference.
3. `git add` the new files, then `nixos-install --flake .#<name>`.
4. Change the placeholder password after first boot.
5. Restore your sops age key to `~/.config/sops/age/keys.txt` **before** running
   `home-manager switch --flake .#<user>` - the home configuration will not
   activate without it.

## Secrets

Secrets are managed with [sops-nix] and encrypted to a single age recipient
(`.sops.yaml`). `secrets/secrets.yaml` holds the encrypted values; decrypting
requires the private key, which lives outside this repo at
`~/.config/sops/age/keys.txt`. Nothing sensitive is stored in the clear here.

[sops-nix]: https://github.com/Mic92/sops-nix

## Caveats

- A number of modules are registered but intentionally not imported - leftovers
  from the Wayland-desktop era (eww, ags, waybar, greetd) kept around rather than
  deleted. They are marked as such in the source.
- `initialPassword` on the host is a placeholder and is meant to be changed after
  install.
- Input pins are deliberately mismatched: nixpkgs tracks unstable while stylix
  sits on `release-24.11` and catppuccin on `release-25.05`. Bumping them is not
  a no-op.
