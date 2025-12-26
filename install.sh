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
  noto-fonts \
  noto-fonts-cjk \
  noto-fonts-emoji \
  noto-fonts-extra \
  telegram-desktop \
  waybar \
  yazi

paru -S --noconfirm \
  android-studio \
  google-chrome \
  polychromatic

sudo gpasswd -a $USER openrazer
echo "✅ Packages installed"

echo "🔄 Updating bash configs..."
rm -f ~/.bashrc ~/.bash_profile
cp .bashrc .bash_profile ~/
echo "✅ Bash configs updated"
