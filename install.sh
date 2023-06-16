#!/bin/sh

echo 'checking if yay is installed'

[ -f /usr/bin/yay ] || ./.scripts/yay.sh

echo 'installing packages'

[ -f /usr/bin/yay ] && yay -S - < .packages.txt

echo 'configuring lightdm'

[ -f /usr/bin/lightdm ] && ./.scripts/lightdm.sh

echo 'configuring window manager'

[ -f /usr/bin/bspwm ] && ./.scripts/bspwm.sh

echo 'rebooting'

systemctl reboot