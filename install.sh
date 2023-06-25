#!/bin/bash 

###########
#Variables#
###########
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
    USER_CONF=/home/$USERNAME/.config
    DIR_U=/home/$USERNAME
    DIR_S=/home/$USERNAME/bspwm-arch
    CONFIG_FILE=/home/$USERNAME/bspwm-arch/setup.conf
    SCRIPT=/home/$USERNAME/bspwm-arch/install.sh
    PACS=/home/$USERNAME/bspwm-arch/packages.txt
    YAYS=/home/$USERNAME/bspwm-arch/yay.txt
}

check-pass-var() {
    if [[ "x$PASSWORD1" = "$PASSWORD1" ]]; then get-password; fi
    }
################
#Functions-Sudo#
################
sudo-nopass() {
    SUDOERS=/etc/sudoers
    SUDOERS_TMP=/tmp/sudoers.tmp
    echo 'Editing /etc/sudoers For User nopassword (root) Access'
    cp $SUDOERS $SUDOERS_TMP
    sed -i 's/^# %wheel ALL=(ALL:ALL) NOPASSWD: ALL/%wheel ALL=(ALL:ALL) NOPASSWD: ALL/' $SUDOERS_TMP
    cp $SUDOERS_TMP $SUDOERS
    rm $SUDOERS_TMP
}

sudo-nopass-reverse() {
    SUDOERS=/etc/sudoers
    SUDOERS_TMP=/tmp/sudoers.tmp
    echo 'Editing /etc/sudoers to Reverse User nopassword (root) Access'
    cp $SUDOERS $SUDOERS_TMP
    sed -i 's/^%wheel ALL=(ALL:ALL) NOPASSWD: ALL/# %wheel ALL=(ALL:ALL) NOPASSWD: ALL/' $SUDOERS_TMP
    cp $SUDOERS_TMP $SUDOERS
    rm $SUDOERS_TMP
}

sudo-withpass() {
    SUDOERS=/etc/sudoers
    SUDOERS_TMP=/tmp/sudoers.tmp
    echo 'Editing /etc/sudoers For User (root) Access'
    cp $SUDOERS $SUDOERS_TMP
    sed -i 's/# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/g' $SUDOERS_TMP
    cp $SUDOERS_TMP $SUDOERS
    rm $SUDOERS_TMP
}
################
#Functions-User#
################
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
}

get-password() {
    read -rs -p "Please enter password: " PASSWORD1
    echo -ne "\n"
    read -rs -p "Please re-enter password: " PASSWORD2
    echo -ne "\n"
    if [[ ! "$PASSWORD1" == "$PASSWORD2" ]]; then
        echo -ne "ERROR! Passwords do not match. \n"
        get-password
    fi
}

set-password() {
    echo "$USERNAME:$PASSWORD1" | chpasswd
}
###########
#Configure#
###########
conf-pacman() {
    PACCONF=/etc/pacman.conf
    sed -i 's/^#ParallelDownloads/ParallelDownloads/g' $PACCONF
    sed -i "/\[multilib\]/,/Include/"'s/^#//' $PACCONF
    pacman -Sy
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
        sudo sed -i 's/gtk-theme-name =*/gtk-theme-name = Layan-Dark/g' /usr/share/gtk-3.0/settings.ini
        sudo sed -i 's/gtk-icon-theme-name =*/gtk-icon-theme-name = Adwaita/g' /usr/share/gtk-3.0/settings.ini
        sudo sed -i 's/gtk-cursor-theme-name =*/gtk-cursor-theme-name = Breeze-Hacked/g' /usr/share/gtk-3.0/settings.ini
        sudo sed -i 's/gtk-font-name =*/gtk-font-name = Cantarell 11/g' /usr/share/gtk-3.0/settings.ini
    fi
    echo 'Xcursor.theme: Breeze-Hacked' >> ~/.Xresources
    xrdb ~/.Xresources
}

conf-dm() {
    echo 'Configuring Display Manager'
    echo 'editing config file'
    sudo sed -i 's/#greeter-session=example-gtk-gnome/greeter-session=lightdm-slick-greeter/g' /etc/lightdm/lightdm.conf
    sudo sed -i 's/#user-session=default/user-session=bspwm/g' /etc/lightdm/lightdm.conf
    echo 'Enabling Display Manager'
    sudo systemctl enable --now lightdm
}

runas-user() {
    if [ -d $DIR_S ]; then rm -rf $DIR_S; fi
    mkdir $DIR_S
    cp -rf ./* $DIR_S/
    mkdir $DIR_S/.config
    cp -rf .config/* $DIR_S/.config/
    su $USERNAME -c "bash $SCRIPT"
}

################
#Functions-Main#
################
install-pacs() {
    if [ -f /var/lib/pacman/db.lck ]; then
        rm -rf /var/lib/pacman/db.lck
        if [ $PACLOCK = 1 ]; then 
            echo "Unable to Unlock pacman database"
            exit
        fi
        PACLOCK=1
        install-pacs
    fi 
    if [[ -f /usr/bin/yay ]]; then
        echo 'Installing Packages'
        sudo pacman -Syu --noconfirm --needed - < $PACS
        yay -S --noconfirm - < $YAYS
    else
        echo 'yay is not installed'
        install-yay
        if [ $YAYTRYINSTALL = 1 ]; then
            echo -e "Failed to install yay,\nDo it manually and then try again"
            exit
        fi
        install-pacs
    fi    
}

install-yay() {
    echo 'Installing yay'
    rm -rf yay
    git clone https://aur.archlinux.org/yay.git
    cd yay
    makepkg -si --noconfirm
    cd ..
    sleep 2
    YAYTRYINSTALL=1
    rm -rf yay
}

restart() {
    echo 'rebooting'
    sleep 3 && systemctl reboot
}

user-install() {
    USERNAME=$(whoami)
    userhome-var
    check-pass-var
    echo "Username=$USERNAME"
    install-pacs
    conf-dm
    conf-theme
    cong-wm
    sudo-withpass
    sudo-nopass-reverse
}

start() {
if [[ $(whoami) = 'root' ]]; then
    echo 'Username=root'
    sudo-nopass
    conf-pacman
    create-user
    get-password
    set-password
    runas-user
else
    user-install
fi
}
start