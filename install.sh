#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR
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
if command -v paru >/dev/null 2>&1; then
  echo "ℹ️  paru already installed; skipping"
else
  tmpdir="$(mktemp -d)"
  trap 'rm -rf "$tmpdir"' EXIT
  git clone --depth 1 https://aur.archlinux.org/paru.git "$tmpdir/paru"
  cd "$tmpdir/paru" && makepkg -si --noconfirm
  cd "$SCRIPT_DIR"
  echo "✅ Paru installation complete"
fi

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
  fzf \
  hypridle \
  hyprlock \
  hyprpaper \
  hyprshot \
  imagemagick \
  libreoffice-fresh \
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
  wireplumber \
  wl-clipboard \
  xdg-desktop-portal-hyprland \
  xorg-xwayland \
  yazi \
  hyprpolkitagent \
  mise \
  uwsm \
  wiremix \
  quickshell \
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
  if [ -f "$HOME/$file" ] && [ ! -L "$HOME/$file" ]; then
    TS=$(date +%Y%m%d%H%M%S)
    echo "Found existing $HOME/$file — moving to ${HOME}/${file}.bak.$TS"
    mv "$HOME/$file" "${HOME}/${file}.bak.$TS"
  else
    rm -f "$HOME/$file"
  fi

  if [ -f "$SCRIPT_DIR/$file" ]; then
    cp "$SCRIPT_DIR/$file" "$HOME/$file"
  else
    echo "ℹ️  Source $SCRIPT_DIR/$file not found — skipping"
  fi
done
echo "✅ Bash configs installed"

# ── 8. Copy $HOME/.config ─────────────────────────────────────────────────────

echo "🔄 Installing configs to $HOME/.config..."

readonly CONFIG_DIRS=(
  bash
  fastfetch
  foot
  hypr
  quickshell
)

for dir in "${CONFIG_DIRS[@]}"; do
  if [ -d "$SCRIPT_DIR/.config/$dir" ]; then
    rm -rf "$HOME/.config/$dir"
    cp -r "$SCRIPT_DIR/.config/$dir" "$HOME/.config/$dir"
  else
    echo "ℹ️  Skipping $dir — no source config at $SCRIPT_DIR/.config/$dir"
  fi
done

if [ -f "$SCRIPT_DIR/.config/starship.toml" ]; then
  rm -f "$HOME/.config/starship.toml"
  cp "$SCRIPT_DIR/.config/starship.toml" "$HOME/.config/starship.toml"
else
  echo "ℹ️  No starship.toml in repo; skipping"
fi
echo "✅ Configs installed"

# ── 8.1 Neovim config: bootstrap LazyVim + Catppuccin ─────────────────────────
echo "🔧 Generating Neovim config for LazyVim + Catppuccin mocha..."

NVIM_CONFIG="$HOME/.config/nvim"
TS=$(date +%Y%m%d%H%M%S)

# Backup existing config instead of destructive removal
if [ -d "$NVIM_CONFIG" ] && [ ! -L "$NVIM_CONFIG" ]; then
  echo "Found existing $NVIM_CONFIG — moving to ${NVIM_CONFIG}.bak.$TS"
  mv "$NVIM_CONFIG" "${NVIM_CONFIG}.bak.$TS"
fi

mkdir -p "$NVIM_CONFIG/lua/config" "$NVIM_CONFIG/lua/plugins"

cat > "$NVIM_CONFIG/init.lua" <<'EOF'
-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")
EOF

cat > "$NVIM_CONFIG/lua/config/lazy.lua" <<'EOF'
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit...", "" },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  spec = {
    { "LazyVim/LazyVim", import = "lazyvim.plugins" },
    { import = "plugins" },
  },
  defaults = {
    lazy = false,
    version = false,
  },
  install = { colorscheme = { "catppuccin", "habamax" } },
  checker = { enabled = true, notify = false },
  performance = {
    rtp = {
      disabled_plugins = {
        "gzip",
        "tarPlugin",
        "tohtml",
        "tutor",
        "zipPlugin",
      },
    },
  },
})
EOF

cat > "$NVIM_CONFIG/lua/plugins/colorscheme.lua" <<'EOF'
return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    opts = {
      flavour = "mocha",
      background = { light = "latte", dark = "mocha" },
      transparent_background = false,
      term_colors = true,
    },
  },
}
EOF

# Run lazy sync only if Neovim is available
if command -v nvim >/dev/null 2>&1; then
  echo "⏳ Running 'nvim --headless +\"Lazy sync\" +qall'..."
  nvim --headless +'Lazy sync' +qall || true
else
  echo "⚠️ Neovim not found; skipping plugin sync. Install Neovim to complete setup."
fi

echo "✅ Neovim config installed at $NVIM_CONFIG"

# ── 9. Enable user systemd services ──────────────────────────────────────────

echo "🔧 Enabling user systemd services..."
if systemctl --user --version >/dev/null 2>&1; then
  systemctl --user enable --now \
    hyprpaper.service \
    hyprpolkitagent.service \
    cliphist.service \
    foot-server.socket || true
  echo "✅ User systemd services enabled (where available)"
else
  echo "⚠️ systemd --user not available; skipping user service enablement"
fi

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

mapfile -t orphan_array < <(pacman -Qtdq || true)
if [[ ${#orphan_array[@]} -gt 0 ]]; then
  sudo pacman -Rns --noconfirm "${orphan_array[@]}"
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
echo "    - Place your wallpaper: $HOME/Pictures/Wallpaper/wallpaper.webp"
echo "    - Reboot into Hyprland"
echo "    - Open nvim — LazyVim will bootstrap itself on first launch"
echo "══════════════════════════════════════════════════════════════════════════"
