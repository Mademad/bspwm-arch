#!/usr/bin/env bash 

###########
#Variables#
###########
SUDOERS=/etc/sudoers
SUDOERS_TMP=/tmp/sudoers.tmp
YAY_LINK=https://aur.archlinux.org/yay-git.git
YAY_DIR=yay-git
USER_CONF=$HOME/.config
GTK3=/usr/share/gtk-3.0/settings.ini
###########
#Functions#
###########
set_option() {
    if grep -Eq "^${1}.*" $CONFIG_FILE; then # check if option exists
        sed -i -e "/^${1}.*/d" $CONFIG_FILE # delete option if exists
    fi
    echo "${1}=${2}" >>$CONFIG_FILE # add option
}

userhome-var() {
    DIR_S=/home/$USERNAME/bspwm-arch
    CONFIG_FILE=/home/$USERNAME/bspwm-arch/setup.conf
    SCRIPT=/home/$USERNAME/bspwm-arch/install.sh
    PACS=/home/$USERNAME/bspwm-arch/packages.txt
    YAYS=/home/$USERNAME/bspwm-arch/yay.txt
}
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
    userhome-var
}

create-user() {
    read -rs -p "Enter Your Username: " USERNAME
    echo -ne "\n"
    useradd -mG wheel -s /bin/bash $USERNAME
    userhome-var
    mkdir $DIR_S
    echo "USERNAME=$USERNAME" >> $CONFIG_FILE
}

get-password() {
    read -rs -p "Please enter password: " PASSWORD1
    echo -ne "\n"
    read -rs -p "Please re-enter password: " PASSWORD2
    echo -ne "\n"
    if [[ "$PASSWORD1" == "$PASSWORD2" ]]; then
        echo ""PASSWORD=$PASSWORD1"" >> $CONFIG_FILE
    else
        echo -ne "ERROR! Passwords do not match. \n"
        get-password
    fi
}

set-password() {
    echo "$USERNAME:$PASSWORD1" | chpasswd
}

runas-user() {
    mkdir $DIR_S/.config
    cp -rf ./* $DIR_S/
    cp -rf .config/* $DIR_S/.config/
    chmod +x $SCRIPT
    su $USERNAME -c "bash $SCRIPT"
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
    echo 'Installing Packages'
    echo "$PASSWORD" | sudo -S pacman -Syu --noconfirm --needed - < $PACS
    yay -S --noconfirm - < $YAYS
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
        echo "$PASSWORD" | sudo -S sed -i 's/gtk-theme-name =*/gtk-theme-name = Layan-Dark/g' /usr/share/gtk-3.0/settings.ini
        echo "$PASSWORD" | sudo -S sed -i 's/gtk-icon-theme-name =*/gtk-icon-theme-name = Adwaita/g' /usr/share/gtk-3.0/settings.ini
        echo "$PASSWORD" | sudo -S sed -i 's/gtk-cursor-theme-name =*/gtk-cursor-theme-name = Breeze-Hacked/g' /usr/share/gtk-3.0/settings.ini
        echo "$PASSWORD" | sudo -S sed -i 's/gtk-font-name =*/gtk-font-name = Cantarell 11/g' /usr/share/gtk-3.0/settings.ini
    fi
    echo 'Xcursor.theme: Breeze-Hacked' >> ~/.Xresources
    xrdb ~/.Xresources
}

conf-dm() {
    echo 'Configuring Display Manager'
    echo 'editing config file'
    echo "$PASSWORD" | sudo -S sed -i 's/#greeter-session=example-gtk-gnome/greeter-session=lightdm-slick-greeter/g' /etc/lightdm/lightdm.conf
    echo "$PASSWORD" | sudo -S sed -i 's/#user-session=default/user-session=bspwm/g' /etc/lightdm/lightdm.conf
    echo 'Enabling Display Manager'
    echo "$PASSWORD" | sudo -S systemctl enable --now lightdm
}

restart() {
    echo 'rebooting'
    sleep 3 && systemctl reboot
}

main() {
    if [[ -f /usr/bin/yay ]]; then
        install-pacs
    else
        echo 'yay is not installed'
        install-yay
        main
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
    get-password
    set-password
    runas-user
else
    USERNAME=$(whoami)
    userhome-var
    check-conf
    echo "Username=$USERNAME"
    main
fi
}
start