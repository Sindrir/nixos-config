# nixos-config

NixOS + home-manager flake for `home-desktop` and `work-laptop`
(both COSMIC), plus a standalone `homeConfigurations.sindreo`.

## Layout

- `flake.nix`: hosts, `customPackagesOverlay`, home-manager `sharedModules`
- `hosts/`, `modules/`: system config
- `home-manager/common.nix`: shared user config; `work.nix` holds work-laptop extras (SOPS secrets)
- `home-manager/dotfiles/`: config files linked into `~` (mostly `mkOutOfStoreSymlink`, so edits apply without a rebuild)
- `packages/<name>/`: custom packages (`default.nix`, optional `hm-module.nix`)
- `secrets/`: SOPS-encrypted; never decrypt or print them

## Workflow

- Flakes only see git-tracked files: `git add` new files before building.
- Run `nix flake check` before saying something is done. CI runs nixpkgs-fmt, statix and deadnix.
- `nurse-fix` auto-fixes formatting and lint.
- Don't run `sudo nixos-rebuild` yourself; tell me to run `nurse` (check + switch).
- `furse` updates flake inputs. Only run it when I ask.

## Conventions

- New package: add `my-package = prev.callPackage ./packages/my-package { };`
  to `customPackagesOverlay`, and add its hm-module to every `sharedModules`
  list in `flake.nix`.
- statix W20: don't repeat top-level keys (`home.packages` and `home.file`);
  merge them into `home = { packages = ...; file = ...; }`.
- Changing a directory symlink to per-file links: remove the old directory
  symlink before rebuilding. Otherwise home-manager's `.bak` backups land
  inside the repo.
