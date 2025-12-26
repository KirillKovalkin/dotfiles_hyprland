#!/bin/bash

set -e

echo "🔧 Installing build dependencies..."
sudo pacman -S --needed base-devel git --noconfirm
echo "✅ Dependencies installed"

echo "📦 Installing paru..."
git clone https://aur.archlinux.org/paru.git
cd paru
makepkg -si
cd ..
rm -rf paru
echo "✅ Paru installation complete"

echo "📥 Installing packages..."
sudo pacman -S --noconfirm \
  alacritty \
  android-tools \
  btop \
  discord \
  fastfetch \
  fuzzel \
  hyprshot \
  mako \
  neovim \
  noto-fonts \
  noto-fonts-cjk \
  noto-fonts-emoji \
  noto-fonts-extra \
  steam \
  telegram-desktop \
  ttf-jetbrains-mono-nerd \
  waybar \
  xorg-xwayland \
  yazi

paru -S --noconfirm \
  android-studio \
  google-chrome \
  polychromatic \
  visual-studio-code-bin

sudo gpasswd -a $USER openrazer
echo "✅ Packages installed"

echo "📝 Installing LazyVim..."
git clone https://github.com/LazyVim/starter ~/.config/nvim
rm -rf ~/.config/nvim/.git
echo "✅ LazyVim installed"

echo "🔄 Updating bash configs..."
rm -f "$HOME/.bashrc" "$HOME/.bash_profile"
cp .bashrc .bash_profile "$HOME/"
echo "✅ Bash configs updated"

echo "🔄 Updating configs in ~/.config..."

CONFIG_DIRS=(
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
  cp -r ".config/$dir" "$HOME/.config/"
done

rm -f "$HOME/.config/starship.toml"
cp ".config/starship.toml" "$HOME/.config/"

echo "✅ Configs updated"

echo "🗑️ Removing unused packages..."
sudo pacman -Rns kitty \
  dunst \
  dolphin \
  wofi \
  sddm

echo "✅ Unused packages removed"

echo "🔄 Updating system..."
sudo pacman -Syu --noconfirm
paru -Syu --noconfirm

orphans=$(pacman -Qtdq)
if [[ -n "$orphans" ]]; then
  sudo pacman -Rns $orphans --noconfirm
  echo "🗑️ Removed orphan packages"
else
  echo "ℹ️ No orphan packages found"
fi

echo "✅ System updated"
