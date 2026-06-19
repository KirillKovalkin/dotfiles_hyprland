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
- Commit the changes made to `install.sh` and `README.md`.
- Add explicit rollback/restore instructions for backups created by the script.
