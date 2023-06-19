#!/bin/sh

if [[ -f /usr/share/gtk-3.0/settings.ini ]]
then 
    sudo sed -i 's/gtk-theme-name =*/gtk-theme-name = Layan-Dark' /usr/share/gtk-3.0/settings.ini
    sudo sed -i 's/gtk-icon-theme-name =*/gtk-icon-theme-name = Adwaita' /usr/share/gtk-3.0/settings.ini
    sudo sed -i 's/gtk-cursor-theme-name =*/gtk-cursor-theme-name = Breeze-Hacked' /usr/share/gtk-3.0/settings.ini
    sudo sed -i 's/gtk-font-name =*/gtk-font-name = Cantarell 11' /usr/share/gtk-3.0/settings.ini
else
    echo 'gtk-theme-name = Layan-Dark' >> /usr/share/gtk-3.0/settings.ini
    echo 'gtk-icon-theme-name = Adwaita' >> /usr/share/gtk-3.0/settings.ini
    echo 'gtk-cursor-theme-name = Breeze-Hacked' >> /usr/share/gtk-3.0/settings.ini
    echo 'gtk-font-name = Cantarell 11' >> /usr/share/gtk-3.0/settings.ini
fi


echo 'Xcursor.theme: Breeze-Hacked' >> ~/.Xresources
xrdb ~/.Xresources