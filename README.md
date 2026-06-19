# dotfiles_hyprland

A set of configuration files and installation scripts for Arch Linux using the Hyprland environment.

Overview:
- Configs included: `~/.config/*`, `~/.bashrc`, `~/.bash_profile`, and more.
- Installation script: `install.sh` — automates package installation and config deployment.

Requirements:
- Arch Linux (or Arch-based systems using `pacman`)
- sudo access
- Recommended to run as a regular user (not root)

Quick start:
```bash
cd /path/to/dotfiles_hyprland
./install.sh
```

What `install.sh` does:
- Updates the system and installs packages from official repos and AUR (via `paru`).
- Copies `pacman.conf` to `/etc/pacman.conf` (a backup is created at `/etc/pacman.conf.bak`).
- Backs up and installs `~/.bashrc` and `~/.bash_profile` (existing files are moved to `*.bak.TIMESTAMP`).
- Copies directories from the repository's `.config/` into `~/.config/` (skips missing sources).
- Sets up Neovim (LazyVim) and attempts to run a plugin sync if `nvim` is installed.

Recommendations and warnings:
- Review the package lists in `install.sh` and `pacman.conf` before running — the script will install and may remove packages automatically.
- The script replaces `/etc/pacman.conf` on the target system (a backup is taken). Edit `pacman.conf` in this repo beforehand if needed.
- If you do not want certain configs applied, remove those folders/files from the repo or edit `install.sh` accordingly.

If you want, I can:
Comprehensive dotfiles and an automated installation script for Arch Linux systems using the Hyprland Wayland compositor.

This repository contains a curated set of user configuration files and a single installation entrypoint, `install.sh`, intended to set up a development desktop environment quickly. The scripts and configs are opinionated; review them before using on a production system.

Contents
--------
- `install.sh` — the main installation and deployment script. Run this from the repository root to apply the dotfiles to your system.
- `pacman.conf` — an example/custom `pacman` configuration included for convenience. `install.sh` can replace `/etc/pacman.conf` (with a backup).
- `.bashrc`, `.bash_profile` — shell configuration files that the script will install into your `$HOME` (existing files are backed up).
- `.config/` — application-specific configuration folders (the script copies selected directories into `~/.config/`).

Prerequisites
-------------
- A running Arch Linux or Arch-based system with `pacman`.
- `sudo` privileges for package installation and system file updates.
- Network access to Arch mirrors and AUR (for AUR packages built via `paru`).

Quick start (recommended safe workflow)
-------------------------------------
1. Inspect repository files locally and edit the package lists or config paths if needed.
2. From the repository root run:

```bash
cd /path/to/dotfiles_hyprland
./install.sh
```

Note: Running `install.sh` will perform system updates and package installs; it may remove packages listed as "unwanted" in the script.

Detailed behavior of `install.sh`
--------------------------------
1. System update: runs `sudo pacman -Syu` at the start to ensure packages and the package database are current.
2. Installs build tools: ensures `base-devel` and `git` are present to build AUR helpers when required.
3. Installs `paru` from AUR if not already installed (the script builds it from the `paru` AUR repo).
4. Installs packages from official repositories using `pacman` and from AUR using `paru`. The script uses `--needed` to avoid reinstalling packages that are already present.
5. Copies `pacman.conf` from the repository to `/etc/pacman.conf`, creating a backup at `/etc/pacman.conf.bak`.
6. Installs shell configs: backs up existing `~/.bashrc` and `~/.bash_profile` (if present) to `~/*.bak.TIMESTAMP` and copies the repository versions into place.
7. Deploys selected directories from `.config/` to `~/.config/`, skipping any source directories that are not present in the repo.
8. Writes a minimal Neovim bootstrap configuration (LazyVim + Catppuccin colourscheme) into `~/.config/nvim` and attempts to run `nvim --headless +'Lazy sync' +qall` if `nvim` is installed.
9. Enables a set of user systemd services with `systemctl --user enable --now` when `systemctl --user` is available.
10. Optionally removes a small set of "unwanted" packages if they are installed.
11. Performs a final system upgrade and removes orphaned packages.

Backups and rollback
--------------------
The script makes conservative backups before making destructive changes:
- `/etc/pacman.conf.bak` — backup of the original system pacman configuration before replacement.
- `~/.bashrc.bak.<TIMESTAMP>` and `~/.bash_profile.bak.<TIMESTAMP>` — backups of existing shell configurations.

Rollback examples
-----------------
Restore `pacman.conf`:
```bash
sudo cp /etc/pacman.conf.bak /etc/pacman.conf
sudo pacman -Syu
```

Restore shell config (example):
```bash
mv ~/.bashrc ~/.bashrc.installed
mv ~/.bashrc.bak.20230101123045 ~/.bashrc
```

If you need to restore multiple files, replace filenames above with the actual backup names created by the script.

Customization
-------------
- To prevent `pacman.conf` from being replaced, remove or comment the copy step in `install.sh`.
- To skip AUR package installation, remove the `paru -S` section or ensure `paru` is not installed so the script will not build it.
- To avoid copying specific app configs, delete the corresponding directory inside the repository's `.config/` or remove it from the `CONFIG_DIRS` array in `install.sh`.
- To add or remove packages, edit the package lists inside `install.sh` (official repo packages and AUR packages).

Neovim and plugins
-------------------
The script bootstraps a minimal LazyVim configuration and attempts a headless plugin sync. If headless sync fails or you prefer to manage plugins interactively, open Neovim and run `:Lazy sync` and follow any prompts.

systemd user services
---------------------
`install.sh` enables a set of services via `systemctl --user`. This step is guarded — it only runs when `systemctl --user` is available. If your environment does not provide a user systemd (for example some minimal containers or alternative init systems), these services will be skipped.

Unwanted packages
-----------------
The script checks for a short list of packages to remove (e.g. alternative desktop components). If any are present they are removed via `sudo pacman -R --noconfirm`. Review and edit the `unwanted` array in `install.sh` before running if you want to change that behavior.

Troubleshooting
---------------
- If the script fails due to network or mirror issues, re-run after confirming network connectivity and mirror availability.
- If a package build from AUR fails, inspect the PKGBUILD logs in the temporary build directory (the script uses a temporary clone). Re-run the AUR build manually if needed.
- For permission errors, ensure your user is in the appropriate groups and that `sudo` prompts are answered.

Security considerations
-----------------------
- Review every package and external repository referenced by the script. Building packages from the AUR executes untrusted PKGBUILDs — inspect them if you have security concerns.
- Running this script will install and remove system packages. Prefer running it in a disposable VM first if you are unsure about system-wide changes.

Development and testing
-----------------------
- Test changes locally by editing `install.sh` and running selected sections rather than the entire script.
- Use a VM or a chroot to validate the full install procedure before applying it to your daily system.

License and attribution
-----------------------
- This repository is intended as a personal dotfiles collection. No explicit license file is included; treat it as a personal configuration set. Add a `LICENSE` file if you intend to share or relicense these files.

Contact and support
-------------------
If you need assistance using these dotfiles, open an issue in this repo or contact the maintainer directly.

Acknowledgements
----------------
This repo uses community tools and themes such as `paru`, `LazyVim`, and `catppuccin`. Thanks to upstream projects for providing those resources.
