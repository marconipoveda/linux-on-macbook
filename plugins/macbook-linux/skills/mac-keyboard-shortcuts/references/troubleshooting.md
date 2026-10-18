# Troubleshooting

**Nothing changed after install.** `journalctl -u keyd -n 30`. If the keyboard shows `DEVICE: ignoring`,
keyd started before the config existed or the config failed to parse: `sudo systemctl restart keyd`.
`keyd: command not found` on Debian/Ubuntu: the binary is `keyd.rvaiya`.

**Config error lines in the journal.** Usually a typo in a key name. Check `keyd list-keys`.

**Cmd and Option feel swapped.** `cat /sys/module/hid_apple/parameters/swap_opt_cmd`. If 1, either remove
`options hid_apple swap_opt_cmd=1` from `/etc/modprobe.d/*` and reboot, or swap `leftmeta`/`leftalt` in [main].

**Cmd+Tab opens and closes instantly / does nothing.** The desktop's app switcher must match the
modifier in `[app_switch:X]`: GNOME `switch-applications` = `<Super>Tab`
(`gsettings get org.gnome.desktop.wm.keybindings switch-applications`), KDE/others Alt+Tab.
Regenerate with the right desktop argument.

**Cmd+Space switches keyboard layout on GNOME.** `scripts/gnome-shortcuts.sh` was not run.

**Can't type @ # [ ] on es/latam/de/fr.** Right Option must stay AltGr: regenerate without
`--both-option-keys`.

**External keyboard (non-Apple).** `[ids] *` remaps it too, so its Windows key becomes Cmd. That's
usually what Mac users want. Otherwise, list only the Apple keyboard's id in `[ids]`.

**Terminal: Cmd+C kills my command.** Expected. Use Cmd+Shift+C/V. keyd can't tell apps apart;
Toshy can, but needs a desktop extension.

**Conflicts.** Toshy, Kinto, xremap, kanata and input-remapper remap the same keys. Run only one.

**Undo.** `sudo systemctl disable --now keyd`, then on GNOME run
`bash ~/.config/mac-keyboard-shortcuts/gnome-backup.sh`.
