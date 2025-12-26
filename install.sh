#!/bin/bash

set -e

echo "📦 Installing paru"
git clone https://aur.archlinux.org/paru.git
cd paru
makepkg -si
echo "✅ Paru installation complete"

echo "📥 Installing packages"
sudo pacman -S noto-fonts noto-fonts-cjk noto-fonts-emoji noto-fonts-extra telegram-desktop fastfetch discord fuzzel btop yazi hyprshot android-tools --noconfirm
paru -S polychromatic google-chrome android-studio --noconfirm
sudo gpasswd -a $USER openrazer
echo "✅ Packages is installed"
