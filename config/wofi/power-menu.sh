#!/usr/bin/env sh

entries=" Shutdown\n Reboot\n⏼ Suspend"

selected=$(echo -e $entries | wofi --width 250 --height 170 -di | awk '{print tolower($2)}')

case $selected in
  suspend)
    exec systemctl suspend;;
  reboot)
    exec systemctl reboot;;
  shutdown)
    exec systemctl poweroff -i;;
esac