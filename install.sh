#!/bin/sh

echo echo 'installing packages'

sudo pacman -Syu --noconfirm - < .packages.txt

echo 'checking if yay is installed'

[ -f /usr/bin/yay ] || sh .scripts/yay.sh

echo 'installing packages from aur'
 
yay -S --noconfirm - < .yay.txt

echo 'configuring lightdm'

[ -f /usr/bin/lightdm ] && sh .scripts/lightdm.sh || echo lightdm not installed

echo 'configuring window manager'

[ -f /usr/bin/bspwm ] && sh .scripts/bspwm.sh || echo bspwm not installed

echo 'configuring theme'

sh .scripts/theme.sh

echo 'rebooting'

systemctl reboot