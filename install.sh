#!/bin/sh

echo 'checking if yay is installed'

[ -f /usr/bin/yay ] || sh .scripts/yay.sh

echo 'installing packages'

[ -f /usr/bin/yay ] && yay -S --noconfirm - < .packages.txt

echo 'configuring lightdm'

[ -f /usr/bin/lightdm ] && sh .scripts/lightdm.sh || echo lightdm not installed

echo 'configuring window manager'

[ -f /usr/bin/bspwm ] && sh .scripts/bspwm.sh || echo bspwm not installed

echo 'rebooting'

systemctl reboot