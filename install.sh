#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR
cd "$SCRIPT_DIR"

warn() {
  echo "⚠️  $*" >&2
}

# ── 1. Build dependencies ─────────────────────────────────────────────────────

echo "🔧 Installing build dependencies..."
if sudo pacman -S --needed --noconfirm base-devel git; then
  echo "✅ Dependencies installed"
else
  warn "Build dependency install failed; continuing"
fi

# ── 2. Install paru ───────────────────────────────────────────────────────────

echo "📦 Installing paru..."
if command -v paru >/dev/null 2>&1; then
  echo "ℹ️  paru already installed; skipping"
else
  tmpdir="$(mktemp -d)"
  trap 'rm -rf "$tmpdir"' EXIT
  if git clone --depth 1 https://aur.archlinux.org/paru.git "$tmpdir/paru" \
    && (cd "$tmpdir/paru" && makepkg -si --noconfirm); then
    echo "✅ Paru installation complete"
  else
    warn "Paru installation failed; AUR steps will be skipped"
  fi
  cd "$SCRIPT_DIR"
fi

# ── 3. Copy pacman.conf ───────────────────────────────────────────────────────

echo "📝 Updating pacman.conf..."
if sudo cp "$SCRIPT_DIR/pacman.conf" /etc/pacman.conf; then
  echo "✅ pacman.conf updated"
else
  warn "pacman.conf update failed; continuing"
fi

# ── 4. Official repo packages ─────────────────────────────────────────────────

echo "📥 Installing official packages..."
if sudo pacman -S --needed --noconfirm \
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
  imv \
  ffmpeg \
  foot \
  fzf \
  hypridle \
  hyprland \
  hyprpaper \
  hyprshot \
  imagemagick \
  jdk11-openjdk \
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
  zoxide; then
  echo "✅ Official packages installed"
else
  warn "Official package install failed; continuing with config deployment"
fi

# ── 5. AUR packages ───────────────────────────────────────────────────────────

echo "📥 Installing AUR packages..."
if command -v paru >/dev/null 2>&1; then
  if paru -S --needed --noconfirm \
    android-studio \
    cursor-bin \
    google-chrome \
    visual-studio-code-bin; then
    echo "✅ AUR packages installed"
  else
    warn "AUR package install failed; continuing with config deployment"
  fi
else
  warn "paru not available; skipping AUR packages"
fi

# ── 6. Copy bash configs ─────────────────────────────────────────────────────

echo "🔄 Installing bash configs..."
for file in .bashrc .bash_profile; do
  rm -f "$HOME/$file"
  if [ -f "$SCRIPT_DIR/$file" ]; then
    cp "$SCRIPT_DIR/$file" "$HOME/$file"
  else
    echo "ℹ️  Source $SCRIPT_DIR/$file not found — skipping"
  fi
done
echo "✅ Bash configs installed"

# ── 7. Copy $HOME/.config ─────────────────────────────────────────────────────

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

mkdir -p "$HOME/.config/systemd/user"
if [ -f "$SCRIPT_DIR/.config/systemd/user/quickshell.service" ]; then
  cp "$SCRIPT_DIR/.config/systemd/user/quickshell.service" "$HOME/.config/systemd/user/quickshell.service"
  echo "✅ quickshell.service installed"
else
  echo "ℹ️  No quickshell.service in repo; skipping"
fi

# ── 7.1 Neovim config: bootstrap LazyVim + Catppuccin ─────────────────────────

echo "🔧 Generating Neovim config for LazyVim + Catppuccin mocha..."

NVIM_CONFIG="$HOME/.config/nvim"
rm -rf "$NVIM_CONFIG"
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

if command -v nvim >/dev/null 2>&1; then
  echo "⏳ Running 'nvim --headless +\"Lazy sync\" +qall'..."
  if ! nvim --headless +'Lazy sync' +qall; then
    warn "Lazy sync failed; run 'nvim' manually to finish plugin setup"
  fi
else
  warn "Neovim not found; skipping plugin sync"
fi

echo "✅ Neovim config installed at $NVIM_CONFIG"

# ── 8. Enable user systemd services ──────────────────────────────────────────

echo "🔧 Enabling user systemd services..."
if systemctl --user --version >/dev/null 2>&1; then
  systemctl --user daemon-reload || warn "systemd user daemon-reload failed"
  if systemctl --user enable --now \
    hyprpaper.service \
    hyprpolkitagent.service \
    cliphist.service \
    foot-server.socket \
    hypridle.service \
    quickshell.service; then
    echo "✅ User systemd services enabled (where available)"
  else
    warn "Some user systemd services failed to enable or start; continuing"
  fi
else
  warn "systemd --user not available; skipping user service enablement"
fi

# ── 9. Remove unwanted packages (if installed) ───────────────────────────────

echo "🗑️  Removing unwanted packages..."
unwanted=(
  dolphin
  dunst
  hyprlock
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
  if sudo pacman -R --noconfirm "${to_remove[@]}"; then
    echo "✅ Removed: ${to_remove[*]}"
  else
    warn "Failed to remove some unwanted packages; continuing"
  fi
else
  echo "ℹ️  None of the unwanted packages are installed"
fi

# ── 10. Full system upgrade ───────────────────────────────────────────────────

echo "🔄 Full system upgrade..."
if sudo pacman -Syu --noconfirm; then
  echo "✅ Official repos upgraded"
else
  warn "Official repo upgrade failed; continuing"
fi

if command -v paru >/dev/null 2>&1; then
  if paru -Syu --noconfirm; then
    echo "✅ AUR packages upgraded"
  else
    warn "AUR upgrade failed; continuing"
  fi
else
  warn "paru not available; skipping AUR upgrade"
fi

mapfile -t orphan_array < <(pacman -Qtdq || true)
if [[ ${#orphan_array[@]} -gt 0 ]]; then
  if sudo pacman -Rns --noconfirm "${orphan_array[@]}"; then
    echo "🗑️  Removed orphan packages"
  else
    warn "Orphan package removal failed; continuing"
  fi
else
  echo "ℹ️  No orphan packages found"
fi

# ── 11. Done ──────────────────────────────────────────────────────────────────

echo ""
echo "══════════════════════════════════════════════════════════════════════════"
echo "  ✅ All done!"
echo ""
echo "  Next steps:"
echo "    - Place your wallpaper: $HOME/Pictures/Wallpaper/wallpaper.webp"
echo "    - Install Steam manually if needed (Super+Shift+S)"
echo "    - Reboot into Hyprland"
echo "    - Open nvim — LazyVim will bootstrap itself on first launch"
echo "══════════════════════════════════════════════════════════════════════════"
