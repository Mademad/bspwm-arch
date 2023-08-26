#!/bin/bash 

###########
#Variables#
###########
GTK3=/usr/share/gtk-3.0/settings.ini
SUDOERS=/etc/sudoers
SUDOERS_TMP=/tmp/sudoers.tmp
PACCONF=/etc/pacman.conf
USER_CONF=$HOME/.config
DIR_U=$HOME
DIR_S=$HOME/bspwm-arch
SCRIPT=$HOME/bspwm-arch/install.sh
PACS=$HOME/bspwm-arch/packages.txt
YAYS=$HOME/bspwm-arch/yay.txt
###########
#Functions#
###########
set_option() {
    if grep -Eq "^${1}.*" $CONFIG_FILE; then # check if option exists
        sed -i -e "/^${1}.*/d" $CONFIG_FILE # delete option if exists
    fi
    echo "${1}=${2}" >>$CONFIG_FILE # add option
}

check-pass-var() {
    if [[ -z "$PASSWORD1" ]]; then
        echo "Password needed."
        get-password
    elif [[ "$PASSWORD1" -ne "$PASSWORD2" ]]; then
        echo "Entered Passwords Do Not Match"
        get-password
    fi
    }
################
#Functions-Sudo#
################
sudo-nopass() {
    echo 'Editing /etc/sudoers For nopassword User (root) Access'
    cp $SUDOERS $SUDOERS_TMP
    sed -i 's/^# %wheel ALL=(ALL:ALL) NOPASSWD: ALL/%wheel ALL=(ALL:ALL) NOPASSWD: ALL/' $SUDOERS_TMP
    cp $SUDOERS_TMP $SUDOERS
    rm $SUDOERS_TMP
}

sudo-nopass-reverse() {
    echo 'Editing /etc/sudoers to Reverse nopassword User (root) Access'
    sudo cp $SUDOERS $SUDOERS_TMP
    sudo sed -i 's/^%wheel ALL=(ALL:ALL) NOPASSWD: ALL/# %wheel ALL=(ALL:ALL) NOPASSWD: ALL/' $SUDOERS_TMP
    sudo cp $SUDOERS_TMP $SUDOERS
    sudo rm $SUDOERS_TMP
}

sudo-withpass() {
    echo 'Editing /etc/sudoers For User (root) Access'
    sudo cp $SUDOERS $SUDOERS_TMP
    sudo sed -i 's/# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/g' $SUDOERS_TMP
    sudo cp $SUDOERS_TMP $SUDOERS
    sudo rm $SUDOERS_TMP
}
################
#Functions-User#
################
create-user() {
    read -rs -p "Enter Your Username: " USERNAME
    echo -ne "\n"
    useradd -mG wheel -s /bin/bash $USERNAME
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
    sed -i 's/^#ParallelDownloads/ParallelDownloads/g' $PACCONF
    sed -i "/\[multilib\]/,/Include/"'s/^#//' $PACCONF
    pacman -Sy --noconfirm --needed pacman-contrib terminus-font
    setfont ter-v16b
    pacman -S --noconfirm --needed curl reflector rsync
    cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup
    iso=$(curl -4 ifconfig.co/country-iso)
    timedatectl set-ntp true
    reflector -a 48 -c $iso -f 5 -l 20 --sort rate --save /etc/pacman.d/mirrorlist
}

conf-wm() {
    echo 'Configuring Window Manager'
    echo -ne "\n"
    echo 'backing up old config files if detected'
    [ -d $USER_CONF ] || mkdir $USER_CONF
    [ -d $USER_CONF/alacritty ] && mv $USER_CONF/alacritty $USER_CONF/alacritty.old
    [ -d $USER_CONF/bspwm ] && mv $USER_CONF/bspwm $USER_CONF/bspwm.old
    [ -d $USER_CONF/sxhkd ] && mv $USER_CONF/sxhkd $USER_CONF/sxhkd.old
    [ -d $USER_CONF/polybar ] && mv $USER_CONF/polybar $USER_CONF/polybar.old
    [ -d $USER_CONF/dunst ] && mv $USER_CONF/dunst $USER_CONF/dunst.old
    echo 'copying config files'
    cp -arf .config/* $USER_CONF/
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
    sudo systemctl enable lightdm
}

runas-user() {
    su $USERNAME -c "git clone https://github.com/Mademad/bspwm-arch"
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
    check-pass-var
    echo "Username=$USERNAME"
    install-pacs
    conf-dm
    conf-theme
    conf-wm
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
    USERNAME=$(whoami)
    user-install
fi
}
"$@"
cd
start
