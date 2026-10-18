#!/bin/bash
# Mac-style trackpad on GNOME (runs as the normal user, no sudo, applies immediately).
# Usage: bash gnome-trackpad.sh [--keep-tap] [--accel adaptive|flat|default]
#   default: tap-to-click off, press with one finger = click, two fingers = right-click, three = middle.
# Saves the previous values to ~/.config/mac-trackpad/undo.sh before changing anything.
set -e
T=org.gnome.desktop.peripherals.touchpad
TAP=false; ACCEL=""
while [ $# -gt 0 ]; do case "$1" in
  --keep-tap) TAP=true ;;
  --accel) ACCEL="$2"; shift ;;
  *) echo "unknown option $1" >&2; exit 1 ;;
esac; shift; done
gsettings list-schemas | grep -qx $T || { echo "Not a GNOME session (schema $T missing)"; exit 1; }
U=~/.config/mac-trackpad; mkdir -p $U
if [ ! -f $U/undo.sh ]; then
  for k in tap-to-click click-method accel-profile; do echo "gsettings set $T $k $(gsettings get $T $k)"; done > $U/undo.sh
fi
gsettings set $T tap-to-click $TAP
gsettings set $T click-method 'fingers'
[ -n "$ACCEL" ] && gsettings set $T accel-profile "'$ACCEL'"
for k in tap-to-click click-method accel-profile natural-scroll disable-while-typing; do echo "$k = $(gsettings get $T $k)"; done
echo "Undo: bash $U/undo.sh"
