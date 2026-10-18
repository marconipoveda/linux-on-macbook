#!/bin/bash
# Turn the Mac layout off. Run: sudo bash uninstall.sh
# Stops keyd and moves its config aside (keyd and the backups stay installed).
[ "$EUID" -eq 0 ] || { echo "run with sudo"; exit 1; }
systemctl disable --now keyd
[ -f /etc/keyd/default.conf ] && mv /etc/keyd/default.conf "/etc/keyd/default.conf.disabled.$(date +%s)"
echo "keyd stopped. On GNOME also run (without sudo): bash ~/.config/mac-keyboard-shortcuts/gnome-backup.sh"
