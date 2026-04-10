if [[ -z $DISPLAY ]] && [[ $(tty) == /dev/tty1 ]]; then
  if uwsm check may-start; then
    exec uwsm start hyprland-uwsm.desktop
  fi
fi
