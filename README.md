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

---

Final notes
-----------

This README is intended as a single-source, final guide for using these dotfiles.

Repository layout (important files):
- `install.sh` — main installation and configuration script. Run from the repository root.
- `pacman.conf` — custom pacman configuration included in the repo. `install.sh` will back up `/etc/pacman.conf` and replace it when run.
- `.bashrc`, `.bash_profile` — shell configs that will be installed to the user's home directory (existing files are backed up).
- `.config/` — directory with per-application config folders (copied to `~/.config/`).

Backups and rollback
- `/etc/pacman.conf.bak` — created if `install.sh` replaces `/etc/pacman.conf`.
- `~/.bashrc.bak.TIMESTAMP` and `~/.bash_profile.bak.TIMESTAMP` — created when existing files are present.

To roll back `pacman.conf` manually:
```bash
sudo cp /etc/pacman.conf.bak /etc/pacman.conf
sudo pacman -Syu
```

To restore previous shell configs (example):
```bash
mv ~/.bashrc ~/.bashrc.new
mv ~/.bashrc.bak.TIMESTAMP ~/.bashrc
```

Manual steps and tips
- Inspect `install.sh` before running it. If you want to prevent certain actions (like replacing `/etc/pacman.conf` or enabling user services), edit the script accordingly.
- If `paru` is not installed, the script will attempt to build it from the AUR. Building AUR helpers requires `base-devel` and `git` (the script already installs them).
- Neovim setup: the script writes a minimal LazyVim bootstrap config and attempts a headless `Lazy sync` if `nvim` is available. If plugin installation fails in headless mode, open Neovim interactively and run `:Lazy sync`.
- `systemctl --user` operations are performed only when available. If your system does not use user systemd (e.g., running a minimal environment), those steps are skipped.

Troubleshooting
- If the script fails due to network or package issues, review the console output. You can run the script step-by-step by executing or copying relevant sections manually.
- If `install.sh` removes a package you need, reinstall it with `sudo pacman -S package-name` or restore from local backups if you have them.

Security and audit suggestions
- Run the script in a VM or disposable environment first to confirm behavior.
- Consider removing packages you don't want to install from the lists in `install.sh`.
- Review `pacman.conf` contents in this repo to ensure mirror/option settings meet your security and performance requirements.

Contributing and changes
- This repo is intended for personal dotfiles. If you plan to share it, consider documenting intended OS versions and any manual steps required for third-party packages.

Contact / Support
- Use the repository issue tracker or contact the maintainer directly for questions about these dotfiles.
