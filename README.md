# dotfiles_hyprland

Personal dotfiles for Arch Linux with [Hyprland](https://hypr.land/), [Quickshell](https://quickshell.outfoxxed.me/) bar, and a single setup script.

## What's included

| Area | Location |
|------|----------|
| Hyprland (Lua config) | `.config/hypr/` |
| Quickshell (bar, launcher, lock screen, OSD) | `.config/quickshell/` |
| Bash (aliases, functions, starship) | `.bashrc`, `.config/bash/` |
| Terminal | `.config/foot/` |
| System info | `.config/fastfetch/` |

Session starts via **uwsm** from `.bash_profile` on tty1.

## Requirements

- Arch Linux (or derivative with pacman)
- sudo access
- Internet connection (official repos + AUR)

## Install

```bash
git clone <repo-url> ~/dotfiles_hyprland
cd ~/dotfiles_hyprland
./install.sh
```

### What `install.sh` does

1. Installs build tools and **paru** (if missing)
2. Copies `pacman.conf` to `/etc/pacman.conf`
3. Installs official and AUR packages (`--needed` skips already-installed)
4. Overwrites bash configs and `.config/{bash,hypr,quickshell,foot,fastfetch}`
5. Generates a fresh LazyVim + Catppuccin Neovim config
6. Enables user services: `hyprpaper`, `hyprpolkitagent`, `cliphist`, `foot-server`
7. Removes conflicting packages: dolphin, dunst, hyprlock, kitty, sddm, wofi
8. Runs a full system upgrade and removes orphan packages

**Warning:** config deployment is destructive — existing configs in the listed directories are deleted and replaced with no backup.

Already-installed packages are not reinstalled; only missing ones are added. A full `-Syu` at the end may upgrade existing packages.

## After install

1. Place wallpaper at `$HOME/Pictures/Wallpaper/wallpaper.webp`
2. Reboot and log in on tty1 (uwsm starts Hyprland)
3. Open `nvim` once to finish LazyVim bootstrap if needed

## Keybindings

Modifier: **Super** (Windows key)

### General

| Binding | Action |
|---------|--------|
| Super + Return | Terminal (foot) |
| Super + Shift + R | App launcher |
| Super + W | Close window |
| Super + Shift + W | Kill window |
| Super + M | Exit session |
| Super + L | Lock screen |
| Super + F | Toggle fullscreen |
| Super + V | Toggle float |
| Super + P | Toggle pseudo-tile |
| Super + J | Toggle split (dwindle) |
| Super + Tab | Next window |
| Super + Shift + Tab | Previous window |
| Super + G | Toggle scratchpad |
| Super + Shift + G | Move to scratchpad |
| Super + 1–0 | Switch workspace |
| Super + Shift + 1–0 | Move window to workspace |
| Super + scroll | Switch workspace |
| Super + drag / Super + RMB drag | Move / resize window |
| Print | Screenshot region (hyprshot → clipboard) |
| Super + Shift + V | Clipboard manager |

### Applications

| Binding | Action |
|---------|--------|
| Super + Shift + B | Browser (Chrome) |
| Super + Shift + Alt + B | Browser incognito |
| Super + Shift + C | VS Code |
| Super + Shift + S | Steam |
| Super + Shift + T | Telegram |
| Super + Shift + M | YouTube Music (PWA) |
| Super + Shift + X | X.com (PWA) |
| Super + Shift + D | Discord (PWA) |
| Super + Shift + L | lamzu.net (PWA) |

### Media & brightness

| Binding | Action |
|---------|--------|
| XF86Audio* | Volume / mute / mic / player controls |
| XF86MonBrightness* | Screen brightness |

Keyboard layout: **us, ru** — toggle with **Super + Space**.

## Shell

Bash config is split under `.config/bash/`:

- `shell` — history, completion
- `init` — mise, starship, zoxide, fzf
- `aliases` — ls (eza), cd (zoxide wrapper), git shortcuts
- `functions` — compression, iso2sd, image/video transcode
- `envs` — EDITOR, bat theme

`cd` with no arguments goes home. Existing directories are entered directly; everything else goes through zoxide fuzzy jump.

## Hyprland notes

- Monitor layout is configured in `.config/hypr/monitors.lua` (machine-specific)
- Wallpapers: `hyprpaper` reads `.config/hypr/hyprpaper.conf`; lock screen uses the same path in Quickshell
- Idle/lock timeouts: `.config/hypr/hypridle.conf`
- Autostart is managed outside this repo (systemd / uwsm)

## Useful commands

```bash
hyprctl reload          # reload Hyprland config
hyprctl hyprpaper reload
qs ipc call launcher toggle
feh --fullscreen image.png   # image viewer
```

## Customization

- App launcher and default apps: `.config/hypr/apps.lua`
- Window rules: `.config/hypr/rules.lua`
- Quickshell themes: `.config/quickshell/themeswitcher/themes.json`
- Personal bash overrides: bottom of `.bashrc`
