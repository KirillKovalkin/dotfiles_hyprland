#!/usr/bin/env bash

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# ── 1. System update first ────────────────────────────────────────────────────

echo "🔄 Updating system before package install..."
sudo pacman -Syu --noconfirm
echo "✅ System updated"

# ── 2. Build dependencies ─────────────────────────────────────────────────────

echo "🔧 Installing build dependencies..."
sudo pacman -S --needed --noconfirm base-devel git
echo "✅ Dependencies installed"

# ── 3. Install paru (binary from AUR — much faster than building from source) ──

echo "📦 Installing paru..."
tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT
git clone --depth 1 https://aur.archlinux.org/paru.git "$tmpdir/paru"
cd "$tmpdir/paru" && makepkg -si --noconfirm
cd "$SCRIPT_DIR"
echo "✅ Paru installation complete"

# ── 4. Official repo packages ─────────────────────────────────────────────────

echo "📥 Installing official packages..."
sudo pacman -S --needed --noconfirm \
  7zip \
  android-tools \
  bash-completion \
  bat \
  brightnessctl \
  btop \
  cliphist \
  eza \
  fastfetch \
  fd \
  feh \
  ffmpeg \
  foot \
  fuzzel \
  fzf \
  hyprlock \
  hyprpaper \
  hyprshot \
  imagemagick \
  libreoffice-fresh \
  mako \
  neovim \
  noto-fonts \
  noto-fonts-cjk \
  noto-fonts-emoji \
  noto-fonts-extra \
  playerctl \
  ripgrep \
  starship \
  telegram-desktop \
  ttf-jetbrains-mono-nerd \
  unzip \
  waybar \
  wireplumber \
  wl-clipboard \
  xdg-desktop-portal-hyprland \
  xorg-xwayland \
  yazi \
  hyprpolkitagent \
  mise \
  uwsm \
  wiremix \
  zoxide
echo "✅ Official packages installed"

# ── 5. AUR packages ───────────────────────────────────────────────────────────

echo "📥 Installing AUR packages..."
paru -S --needed --noconfirm \
  android-studio \
  cursor-bin \
  google-chrome \
  visual-studio-code-bin
echo "✅ AUR packages installed"

# ── 6. Copy pacman.conf ───────────────────────────────────────────────────────

echo "📝 Updating pacman.conf..."
sudo cp /etc/pacman.conf /etc/pacman.conf.bak
sudo cp "$SCRIPT_DIR/pacman.conf" /etc/pacman.conf
echo "✅ pacman.conf updated (backup at /etc/pacman.conf.bak)"

# ── 7. Copy bash configs ─────────────────────────────────────────────────────

echo "🔄 Installing bash configs..."
for file in .bashrc .bash_profile; do
  rm -f "$HOME/$file"
  cp "$SCRIPT_DIR/$file" "$HOME/$file"
done
echo "✅ Bash configs installed"

# ── 8. Copy ~/.config ─────────────────────────────────────────────────────────

echo "🔄 Installing configs to ~/.config..."

readonly CONFIG_DIRS=(
  alacritty
  bash
  fastfetch
  fuzzel
  hypr
  mako
  nvim
  waybar
)

for dir in "${CONFIG_DIRS[@]}"; do
  rm -rf "$HOME/.config/$dir"
  cp -r "$SCRIPT_DIR/.config/$dir" "$HOME/.config/$dir"
done

rm -f "$HOME/.config/starship.toml"
cp "$SCRIPT_DIR/.config/starship.toml" "$HOME/.config/starship.toml"
echo "✅ Configs installed"

# ── 9. Enable user systemd services ──────────────────────────────────────────

echo "🔧 Enabling user systemd services..."
systemctl --user enable --now \
  hyprpaper.service \
  waybar.service \
  hyprpolkitagent.service \
  mako.service \
  cliphist.service \
  foot-server.socket

echo "✅ User systemd services enabled"

# ── 10. Remove unwanted packages (if installed) ───────────────────────────────

echo "🗑️  Removing unwanted packages..."
unwanted=(
  dolphin
  dunst
  kitty
  sddm
  wofi
)

to_remove=()
for pkg in "${unwanted[@]}"; do
  if pacman -Qi "$pkg" &>/dev/null; then
    to_remove+=("$pkg")
  fi
done

if [[ ${#to_remove[@]} -gt 0 ]]; then
  sudo pacman -R --noconfirm "${to_remove[@]}"
  echo "✅ Removed: ${to_remove[*]}"
else
  echo "ℹ️  None of the unwanted packages are installed"
fi

# ── 11. Full system upgrade ───────────────────────────────────────────────────

echo "🔄 Full system upgrade..."
sudo pacman -Syu --noconfirm
paru -Syu --noconfirm

orphans="$(pacman -Qtdq || true)"
if [[ -n "$orphans" ]]; then
  sudo pacman -Rns --noconfirm $orphans
  echo "🗑️  Removed orphan packages"
else
  echo "ℹ️  No orphan packages found"
fi

# ── 12. Done ──────────────────────────────────────────────────────────────────

echo ""
echo "══════════════════════════════════════════════════════════════════════════"
echo "  ✅ All done!"
echo ""
echo "  Next steps:"
echo "    - Place your wallpaper: ~/Pictures/Wallpaper/wallpaper.webp"
echo "    - Reboot into Hyprland"
echo "    - Open nvim — LazyVim will bootstrap itself on first launch"
echo "══════════════════════════════════════════════════════════════════════════"
