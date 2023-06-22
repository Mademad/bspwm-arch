#!/bin/sh

result=$(xset q | grep "Scroll Lock: off")
if [ -z "$result" ]; then # Scroll Lock must be on
  echo "Off"
  xset -led named "Scroll Lock"
else
  echo "On"
  xset led named "Scroll Lock"
fi
