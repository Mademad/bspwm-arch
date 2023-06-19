#!/bin/sh

echo ' installing yay'

git clone https://aur.archlinux.org/yay-git.git
cd yay-git
makepkg -si

sleep 1 && cd ..

rm -rf yay-git
