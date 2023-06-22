#!/bin/sh

echo 'installing packages'

sudo pacman -Syu --noconfirm - < .packages.txt

echo 'checking if yay is installed'

[ -f /usr/bin/yay ] || bash .scripts/yay.sh

echo 'installing packages from aur'
 
yay -S --noconfirm - < .yay.txt

echo 'configuring lightdm'

[ -f /usr/bin/lightdm ] && bash .scripts/lightdm.sh || echo lightdm not installed

echo 'configuring window manager'

[ -f /usr/bin/bspwm ] && bash .scripts/bspwm.sh || echo bspwm not installed

echo 'configuring theme'

bash .scripts/theme.sh

echo 'rebooting'

systemctl reboot