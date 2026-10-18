#!/bin/bash
# GNOME only, runs as the normal user (no sudo). Makes Cmd+Space open Activities search.
# keyd sends Super+Space for Cmd+Space, which GNOME uses to switch input sources by default.
# Saves the previous values to ~/.config/mac-keyboard-shortcuts/gnome-backup.sh for undo.
set -e
WM=org.gnome.desktop.wm.keybindings; SH=org.gnome.shell.keybindings
BK=~/.config/mac-keyboard-shortcuts; mkdir -p "$BK"
[ -f "$BK/gnome-backup.sh" ] || cat > "$BK/gnome-backup.sh" <<B
gsettings set $WM switch-input-source "$(gsettings get $WM switch-input-source)"
gsettings set $WM switch-input-source-backward "$(gsettings get $WM switch-input-source-backward)"
gsettings set $SH toggle-overview "$(gsettings get $SH toggle-overview)"
B
N=$(gsettings get org.gnome.desktop.input-sources sources | grep -o "('" | wc -l)
if [ "$N" -gt 1 ]; then
  # Several layouts: move layout switching to Ctrl+Space, the macOS default
  gsettings set $WM switch-input-source "['<Control>space', 'XF86Keyboard']"
  gsettings set $WM switch-input-source-backward "['<Shift><Control>space', '<Shift>XF86Keyboard']"
  echo "Layout switching moved to Ctrl+Space ($N input sources)"
else
  gsettings set $WM switch-input-source "['XF86Keyboard']"
  gsettings set $WM switch-input-source-backward "['<Shift>XF86Keyboard']"
fi
gsettings set $SH toggle-overview "['<Super>space']"
echo "Cmd+Space now opens Activities search. Undo: bash $BK/gnome-backup.sh"
