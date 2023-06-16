#!/bin/sh

echo ' installing yay'

sudo pacman -S base-devel
git clone https://aur.archlinux.org/yay-git.git
cd yay-git
makepkg -si

sleep 1 && cd ..