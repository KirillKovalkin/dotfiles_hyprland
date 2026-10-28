# dotfiles_hyprland

Personal dotfiles for Arch Linux with [Hyprland](https://hypr.land/), [Quickshell](https://quickshell.outfoxxed.me/) bar, and a single setup script.

Session starts via **uwsm** from `.bash_profile` on tty1.

## Hardware (this desktop)

| Part | Value |
|------|--------|
| CPU | Intel Core i5-11500 |
| GPU | AMD Radeon RX 9060 XT (drives monitors) |
| VA-API | `LIBVA_DRIVER_NAME=radeonsi` in `.config/uwsm/env` |
| Monitors | DP-1 `1920x1080@240`, HDMI-A-1 `1920x1080@60` |

Host layout: `.config/hypr/machine.lua`.  
App/toolkit env (incl. LIBVA): `.config/uwsm/env` — required for uwsm; Hyprland `env.lua` alone is not enough.

## What's included

| Area | Location |
|------|----------|
| Hyprland | `.config/hypr/` |
| Quickshell | `.config/quickshell/` |
| uwsm env | `.config/uwsm/env` |
| Bash | `.bashrc`, `.config/bash/` |
| Terminal | `.config/foot/` |
| Quickshell unit | `.config/systemd/user/quickshell.service` |

## Install

```bash
git clone <repo-url> ~/dotfiles_hyprland
cd ~/dotfiles_hyprland
./install.sh
```

Flags:

```bash
DRY_RUN=1 ./install.sh   # plan only
BACKUP=0 ./install.sh    # no *.bak-* copies
UPGRADE=0 ./install.sh   # skip final -Syu
NVIM=0 ./install.sh      # keep existing ~/.config/nvim
```

### What `install.sh` does

1. Build tools + **paru** (if missing)
2. Copies `pacman.conf` → `/etc/pacman.conf`
3. Official packages (`--needed`), including portals, `lm_sensors`, `iw`
4. AUR packages via paru (if available)
5. Backup (default) + deploy bash and `.config/{bash,hypr,quickshell,foot,fastfetch,uwsm}`
6. `quickshell.service` → user systemd
7. LazyVim Neovim (skip with `NVIM=0`)
8. Enable: `hyprpaper`, `hyprpolkitagent`, `cliphist`, `foot-server`, `hypridle`, `quickshell`
9. Remove if present: dolphin, dunst, hyprlock, kitty, sddm, wofi
10. Full upgrade + orphans (skip with `UPGRADE=0`)

**Warning:** deploy replaces listed config dirs; `BACKUP=1` keeps `*.bak-<timestamp>`.

## After install

1. Wallpaper: `$HOME/Pictures/Wallpaper/wallpaper.webp`
2. Reboot → tty1
3. Steam manually if needed (`Super+Shift+S`)

```bash
systemctl --user status hyprpaper hypridle quickshell cliphist
```

Idle/lock: `.config/hypr/hypridle.conf` (dim 10m → lock 15m → DPMS 20m → suspend 60m).

## Keybindings

Modifier: **Super**

| Binding | Action |
|---------|--------|
| Super + Return | Terminal (foot) |
| Super + Shift + R | App launcher |
| Super + W / Shift+W | Close / kill |
| Super + M | Exit session |
| Super + L | Lock |
| Super + F / V / P / J | Fullscreen / float / pseudo / split |
| Super + Tab | Next window |
| Super + G | Scratchpad |
| Super + 1–0 | Workspaces |
| Print | Region shot → clipboard |
| Super + Shift + V | Clipboard manager |
| Super + Shift + B / Alt+B | Chrome / incognito |
| Super + Shift + C / S / T | VS Code / Steam / Telegram |
| Super + Shift + M/X/D/L | PWAs |

Layout **us,ru** — Super + Space. XF86 keys: volume / brightness / playerctl.

## Shell

`.config/bash/`: `shell`, `init`, `aliases`, `functions`, `envs`.  
Overrides: bottom of `.bashrc`.

## Useful commands

```bash
hyprctl reload
hyprctl hyprpaper reload
systemctl --user restart quickshell hypridle
qs ipc call launcher toggle
```

## Customization

- Host / monitors: `.config/hypr/machine.lua`
- App env / LIBVA: `.config/uwsm/env`
- Wallpaper: `.config/hypr/hyprpaper.conf` + `.config/quickshell/wallpaper.path`
- Gaming bar auto-hide output: `.config/quickshell/machine.conf`
- Apps / rules: `.config/hypr/apps.lua`, `rules.lua`
- Themes: `.config/quickshell/themeswitcher/themes.json`
