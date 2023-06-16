#!/bin/sh

echo 'editing config file'

sudo sed -i 's/#greeter-session=example-gtk-gnome/greeter-session=lightdm-slick-greeter/' /etc/lightdm/lightdm.conf

sudo sed -i 's/#user-session=default/user-session=bspwm/' /etc/lightdm/lightdm.conf

echo 'enabling lightdm'

sudo systemctl enable lightdm