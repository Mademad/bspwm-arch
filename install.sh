#!/bin/bash 

###########
#Variables#
###########
SUDOERS=/etc/sudoers
SUDOERS_TMP=/tmp/sudoers.tmp
YAY_LINK=https://aur.archlinux.org/yay-git.git
YAY_DIR=yay-git
PACFILE=.packages.txt
YAYFILE=.yay.txt
USER_CONF=$HOME/.config
GTK3=/usr/share/gtk-3.0/settings.ini
###########
#Functions#
###########
################
#Functions-User#
################
sudo-access() {
    echo 'Editing /etc/sudoers For User (root) Access'
    cp $SUDOERS $SUDOERS_TMP
    sed -i 's/# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/g' $SUDOERS_TMP
    cp $SUDOERS_TMP $SUDOERS
    rm $SUDOERS_TMP
}

check-conf() {
    if [[ -f $CONFIG_FILE ]]; then
        source $CONFIG_FILE
    else
        get-user
        get-password
        start
    fi
}

get-user() {
    USERNAME=$(whoami)
    DIR_S=/home/$USERNAME/bspwm-arch
    CONFIG_FILE=/home/$USERNAME/bspwm-arch/config.txt
    SCRIPT=/home/$USERNAME/bspwm-arch/install.sh
    echo 'USERNAME=$USERNAME' >> config.txt
}

get-password() {
    read -rs -p "Please enter password: " PASSWORD1
    echo -ne "\n"
    read -rs -p "Please re-enter password: " PASSWORD2
    echo -ne "\n"
    if [[ "$PASSWORD1" == "$PASSWORD2" ]]; then
        echo "PASSWORD1=$PASSWORD1" >> config.txt
    else
        echo -ne "ERROR! Passwords do not match. \n"
        get-password
    fi
}

create-user() {
    read -rs -p "Enter Your Username: " USERNAME
    echo -ne "\n"
    useradd -mG wheel -s /bin/bash $USERNAME
    echo "USERNAME=$USERNAME" >> config.txt
    get-password
    set-password

}

set-password() {
    echo "$USERNAME:$PASSWORD1" | chpasswd
}

runas-user() {
    mkdir $DIR_S
    cp -r ./* $DIR_S/
    chmod +x $SCRIPT
    su -c /bin/bash $SCRIPT
}

################
#Functions-Main#
################

install-yay() {
    echo 'Installing yay'
    git clone $YAY_LINK
    cd $YAY_DIR
    makepkg -si --noconfirm
    sleep 1 && cd ..
    rm -rf yay-git
}

install-pacs() {
    echo 'installing packages'
    echo '$PASSWORD1' | sudo -S pacman -Syu --noconfirm --needed - < $PACFILE
    yay -S --noconfirm - < $YAYFILE
}

conf-wm() {
    echo 'Configuring Window Manager'
    echo -ne "\n"
    echo 'backing up old config files if detected'
    [ -d $USER_CONF ] || mkdir $USER_CONF
    [ -d $USER_CONF/alacritty ] && mv $USER_CONF/alacritty $USER_CONF/alacritty.old || mkdir $USER_CONF/alacritty
    [ -d $USER_CONF/bspwm ] && mv $USER_CONF/bspwm $USER_CONF/bspwm.old || mkdir $USER_CONF/bspwm
    [ -d $USER_CONF/sxhkd ] && mv $USER_CONF/sxhkd $USER_CONF/sxhkd.old || mkdir $USER_CONF/sxhkd
    [ -d $USER_CONF/polybar ] && mv $USER_CONF/polybar $USER_CONF/polybar.old || mkdir $USER_CONF/polybar
    [ -d $USER_CONF/dunst ] && mv $USER_CONF/dunst $USER_CONF/dunst.old || mkdir $USER_CONF/dunst
    echo 'copying config files'
    cp -rf .config/* $USER_CONF/
}

conf-theme() {
    echo 'Configuring Theme'
    if [[ -f $GTK3 ]]; then 
        echo '$PASSWORD' | sudo -S sed -i 's/gtk-theme-name =*/gtk-theme-name = Layan-Dark/g' /usr/share/gtk-3.0/settings.ini
        echo '$PASSWORD' | sudo -S sed -i 's/gtk-icon-theme-name =*/gtk-icon-theme-name = Adwaita/g' /usr/share/gtk-3.0/settings.ini
        echo '$PASSWORD' | sudo -S sed -i 's/gtk-cursor-theme-name =*/gtk-cursor-theme-name = Breeze-Hacked/g' /usr/share/gtk-3.0/settings.ini
        echo '$PASSWORD' | sudo -S sed -i 's/gtk-font-name =*/gtk-font-name = Cantarell 11/g' /usr/share/gtk-3.0/settings.ini
    fi
    echo 'Xcursor.theme: Breeze-Hacked' >> ~/.Xresources
    xrdb ~/.Xresources
}

conf-dm() {
    echo 'Configuring Display Manager'
    echo 'editing config file'
    echo '$PASSWORD' | sudo -S sed -i 's/#greeter-session=example-gtk-gnome/greeter-session=lightdm-slick-greeter/g' /etc/lightdm/lightdm.conf
    echo '$PASSWORD' | sudo -S sed -i 's/#user-session=default/user-session=bspwm/g' /etc/lightdm/lightdm.conf
    echo 'Enabling Display Manager'
    echo '$PASSWORD' | sudo -S systemctl enable --now lightdm
}

restart() {
    echo 'rebooting'
    sleep 3 && systemctl reboot
}

main() {
    if [[ -f /usr/bin/yay ]]; then
        install-yay
        install-pacs
    else
        echo 'yay is not installed'
    fi
    conf-dm
    conf-theme
    cong-wm
    restart
}

start() {
if [[ $(whoami) == 'root' ]]; then
    echo 'Username=root'
    sudo-access
    create-user
    runas-user
else
    echo 'Username=$USERNAME'
    check-conf
    main
fi
}
get-user
start