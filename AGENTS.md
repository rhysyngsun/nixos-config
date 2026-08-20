# AGENTS.md

Personal NixOS + home-manager flake, built on [flake-parts] and organized with
the **[dendritic pattern]**. One host (`lilith`), two standalone home-manager
configs (`nathan`, `rhysyngsun`). `x86_64-linux` only.

If you have not met the dendritic pattern before, read the link - this repo will
not make sense otherwise, and the usual NixOS-config instincts are wrong here.

[flake-parts]: https://flake.parts
[dendritic pattern]: https://github.com/mightyiam/dendritic

## What dendritic means here

- **Every `.nix` file under `modules/` is a flake-parts module**, not a NixOS or
  home-manager module. Its job is to *register* something under
  `flake.modules.<class>.<name>`.
- Organization is **by aspect, not by host**. A concern (git, zsh, AI tooling)
  lives in one file and is offered to whichever host or home config wants it.
- Configurations are **derived, not declared**. Nothing enumerates hosts or
  users; `flake.nix` filters the registry by name prefix.

Two deviations from upstream dendritic - they are deliberate, do not "fix" them:

- `import-tree` is hand-rolled in `flake.nix:16` as a `lib.fileset` walk rather
  than the `mightyiam/import-tree` input. Same semantics, `_`-prefix skip
  included.
- The registry is typed `lazyAttrsOf (lazyAttrsOf raw)`, not `deferredModule`, so
  **each `flake.modules.<class>.<name>` must be defined by exactly one file.**
  Merging happens across different names, not within one.

## Commands

Run from the repo root. The justfile is `.justfile` - note the leading dot.

| task | command |
| --- | --- |
| dev shell | `direnv allow`, or `nix develop` |
| format | `nix fmt` |
| check | `nix flake check` (includes `checks.formatting`) |
| dry build the system | `just dry-build-system` |
| apply to system | `just switch-system` / `just boot-system` (sudo) |
| apply home config | `just switch-user` |
| update flake inputs | `just update` |
| repin package sources | `just update-pkgs` (nvfetcher) |
| repin one source | `just update-pkgs -f <regex>` |

`.envrc` is `use flake . --impure` - the `--impure` matters.

`update-pkgs` forwards any extra arguments straight to `nvfetcher`. Bare, it
repins **every** entry in `nvfetcher.toml`, so an unrelated branch-tracking source
will drift into your diff. Scope it with `-f <regex>` when you only meant to touch
one. `--keep-going` is the other useful one: it lets the run finish when a single
source fails to resolve, instead of aborting before anything is written.

**Stop at `nix flake check` and `just dry-build-system`.** The `switch-*` and
`boot-*` recipes mutate the running machine and need sudo; propose them and let
the user run them.

Every build recipe depends on `git-stage`, which runs `git add .`. This is not
cosmetic: **flakes only see tracked files, so a new `.nix` file you have not
`git add`ed does not exist to the build.** If a change appears to have no effect,
check this first.

## The module contract

`flake.nix:16` imports **every** `.nix` file under `./modules`, recursively.
There is no import list to update - dropping a file in registers it. Files and
directories whose name starts with `_` are skipped.

The corollary matters: **a file under `modules/` that is not a valid flake-parts
module breaks the entire flake.** That is exactly why the plain home-manager
tree lives in `home/` and the nvf tree in `nvf/`, both outside `modules/`, each
reached through a one-line shim module.

Prefixes are load-bearing (`flake.nix:38-39`, `74-112`):

| directory | prefix | class | becomes |
| --- | --- | --- | --- |
| `modules/hosts/` | `host-` | `nixos` | `nixosConfigurations.<name>` |
| `modules/home/` | `home-` | `homeManager` | `homeConfigurations.<name>` |
| `modules/programs/` | `programs-` | `homeManager` | reusable aspect |
| `modules/services/` | `services-` | `nixos` | reusable aspect |
| `modules/themes/` | `theme-` | `homeManager` | reusable aspect |

So `flake.modules.nixos.host-lilith` produces `.#lilith`, and
`flake.modules.homeManager.home-nathan` produces `.#nathan`. The attribute name
matches the filename stem.

### File skeleton

Two levels of function. The outer one receives flake-parts arguments; the inner
one is the ordinary NixOS or home-manager module.

```nix
{ ... }:                          # outer: flake-parts args (inputs, config, lib)
{
  flake.modules.homeManager.programs-foo =
    { config, pkgs, lib, ... }:   # inner: ordinary home-manager module
    {
      programs.foo.enable = true;
    };
}
```

To reference another module, capture the outer arguments as `@top` and go through
the registry - **never a relative path import**:

```nix
{ inputs, ... }@top:
{
  flake.modules.homeManager.home-someone = {
    imports = [
      top.config.flake.modules.homeManager.programs-foo
      inputs.stylix.homeManagerModules.stylix
    ];
  };
}
```

See `modules/home/home-nathan.nix:22-50` for the real thing.

`inputs` reaches module bodies through `specialArgs = { inherit inputs; }`
(NixOS) and `extraSpecialArgs = { inherit system inputs; }` (home-manager), so an
inner module can just take `{ inputs, ... }`.

**There is no `lib/`, no `myLib`, no custom options namespace, no `enable` flags,
and no `default.nix` aggregators.** Modules are unconditional config blobs,
composed by explicit `imports` lists in the `host-*` and `home-*` roll-ups. Do
not invent an options layer.

## Layout

`modules/` holds registrations. The other directories hold the payload.

- `hosts/lilith/` - `hardware-configuration.nix` and `open-learning/` (MIT hosts
  entries, CA cert). Imported *by* `modules/hosts/host-lilith.nix`, not directly.
- `home/` - plain home-manager modules, deliberately outside `modules/`.
  `home/<user>/home.nix` carries per-user identity (username, homeDirectory,
  stateVersion) and is imported by that user's roll-up. `home/wayland/` is
  reached through `modules/programs/programs-wayland.nix`.
- `nvf/` - Neovim in nvf's own `vim.*` schema, built against `pkgs.pkgs-edge` by
  `modules/programs/programs-neovim.nix`.
- `pkgs/` - custom packages exported as the `additions` overlay
  (`pkgs/default.nix`): `rice`, `mit/` (cacert, agent-kit, witan via uv2nix),
  `krita-plugins`, `vimPlugins`, `localSources`. **`pkgs/_sources/` is
  nvfetcher-generated - never hand-edit it**; change `nvfetcher.toml` and run
  `just update-pkgs -f <name>`.
- `overlays/default.nix` - `additions`, `modifications`, `unstable-packages`.
  Cross-channel packages are `pkgs.pkgs-unstable.<x>` and `pkgs.pkgs-edge.<x>`
  (**not** `pkgs.unstable`).
- `themes/` - stylix config and wallpapers (`wallpaper.mp4` is git-lfs).
- `nix-settings.nix`, `nixpkgs.nix`, `shell.nix`, `treefmt.nix`, `treefmt.toml`.

## Recipes

**Add a home-manager aspect.** Create `modules/programs/programs-foo.nix` using
the skeleton above, then add
`top.config.flake.modules.homeManager.programs-foo` to the `imports` in
`modules/home/home-nathan.nix` (and `home-rhysyngsun.nix` if it applies), then
`git add`. Registering alone does nothing - a roll-up must import it.

**Add a host.** Create `modules/hosts/host-<name>.nix` registering
`flake.modules.nixos.host-<name>`. `nixosConfigurations.<name>` appears with no
edit to `flake.nix`. Note `.justfile` hardcodes `.#lilith`.

**Add a package.** If it needs a pinned upstream source, add it to
`nvfetcher.toml` and run `just update-pkgs -f <name>` - scoping it keeps the diff
to the source you just added. Then write `pkgs/<name>.nix` and add a
`callPackage` line to `pkgs/default.nix`.

## Conventions

nixfmt-rfc-style via treefmt - **not** alejandra. Two-space indent, kebab-case,
module attribute name equal to the filename stem. `with lib;` and `with pkgs;`
are idiomatic here. Comments explain *why*; preserve them, including the
"intentionally not imported" markers.

`nix flake check` fails on unformatted Nix, so run `nix fmt` before checking.

## Secrets - sops-nix, do not touch

Single age recipient, declared in `.sops.yaml`; the private key lives at
`~/.config/sops/age/keys.txt` and is not in this repo.

`secrets/secrets.yaml` is encrypted. **Never `cat` it, decrypt it, re-encrypt it,
or commit plaintext derived from it.** Adding a secret is interactive - the user
runs `sops secrets/secrets.yaml`, then the module declares
`sops.secrets."path" = { };`.

`agenix`/`ragenix` is a flake input and is in the devShell, but no module uses
it. sops-nix is the only secrets mechanism here - do not reach for agenix.

## Gotchas

- Untracked files are invisible to the flake. Worth repeating - it is the most
  common first-try failure.
- Inputs are pinned on purpose and intentionally mismatched: `nixpkgs` follows
  **unstable**; `nixpkgs-stable` (26.05) is declared but unused; stylix is on
  `release-24.11`, catppuccin on `release-25.05`, wezterm on a fixed rev. Do not
  bump these opportunistically.
- home-manager option collisions are resolved with `disabledModules` - see the
  anyrun case in `modules/home/home-nathan.nix:8-15`.
- Several modules are registered but intentionally not imported: `programs-eww`,
  `programs-wayland`, `programs-ags`, `programs-bin`, `programs-productivity`,
  `theme-gtk`, `theme-cursors`, `services-greetd`. Do
  not wire them in as cleanup. `programs-bin` references a `../../bin` that does
  not exist and would fail if imported.
- `sops.age.keyFile` is an absolute per-user path spelled out in each home
  roll-up (`/home/<user>/.config/sops/age/keys.txt`), not derived from
  `config.home.homeDirectory`. A new home config needs its own path, not a copy
  of the neighbour's.
