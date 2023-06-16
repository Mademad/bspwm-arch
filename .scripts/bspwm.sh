#!/bin/sh

echo 'backing up old config files if detected'

[ -d $HOME/.config ] || mkdir $HOME/.config

[ -d $HOME/.config/alacritty ] && mv $HOME/.config/alacritty $HOME/.config/alacritty.old || mkdir $HOME/.config/alacritty

[ -d $HOME/.config/bspwm ] && mv $HOME/.config/bspwm $HOME/.config/bspwm.old || mkdir $HOME/.config/bspwm

[ -d $HOME/.config/sxhkd ] && mv $HOME/.config/sxhkd $HOME/.config/sxhkd.old || mkdir $HOME/.config/sxhkd

[ -d $HOME/.config/polybar ] && mv $HOME/.config/polybar $HOME/.config/polybar.old || mkdir $HOME/.config/polybar

[ -d $HOME/.config/dunst ] && mv $HOME/.config/dunst $HOME/.config/dunst.old || mkdir $HOME/.config/dunst

echo 'copying config files'

cp -r .config/* $HOME/.config/