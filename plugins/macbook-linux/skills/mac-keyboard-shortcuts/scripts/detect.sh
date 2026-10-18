#!/bin/bash
# Read-only environment report for the mac-keyboard-shortcuts skill. Needs no root.
echo "== OS";        . /etc/os-release 2>/dev/null && echo "$PRETTY_NAME (id=$ID, like=${ID_LIKE:-none})"
echo "== Hardware";  cat /sys/class/dmi/id/product_name 2>/dev/null || echo unknown
echo "== Desktop";   echo "desktop=${XDG_CURRENT_DESKTOP:-unknown} session=${XDG_SESSION_TYPE:-unknown}"
command -v gnome-shell >/dev/null && gnome-shell --version
command -v plasmashell >/dev/null && plasmashell --version 2>/dev/null
echo "== Keyboards"; awk -v RS= '/Handlers=.*kbd/ && /EV=1[0-9a-f]*3\n/ {match($0,/Name="[^"]*"/); print "  " substr($0,RSTART+5,RLENGTH-5)}' /proc/bus/input/devices
echo "== Apple kernel options (swap_opt_cmd=1 would already swap Option/Cmd)"
for p in swap_opt_cmd swap_fn_leftctrl fnmode; do
  f=/sys/module/hid_apple/parameters/$p; [ -r $f ] && echo "  hid_apple.$p=$(cat $f)"
done
echo "== Layout"
if command -v gsettings >/dev/null && gsettings list-schemas | grep -q org.gnome.desktop.input-sources; then
  echo "  gnome sources: $(gsettings get org.gnome.desktop.input-sources sources)"
  echo "  gnome xkb-options: $(gsettings get org.gnome.desktop.input-sources xkb-options)"
fi
[ -r ~/.config/kxkbrc ] && grep -E '^(LayoutList|Options)=' ~/.config/kxkbrc | sed 's/^/  kde /'
localectl status 2>/dev/null | grep -i 'x11 layout\|x11 options' | sed 's/^ */  /'
echo "== keyd"
for b in keyd keyd.rvaiya; do command -v $b >/dev/null && echo "  binary: $(command -v $b)"; done
systemctl is-active keyd 2>/dev/null | sed 's/^/  service: /'
ls /etc/keyd/ 2>/dev/null | sed 's/^/  \/etc\/keyd\//'
echo "== Package availability"
if command -v apt-cache >/dev/null; then apt-cache policy keyd 2>/dev/null | grep -E 'Installed|Candidate' | sed 's/^ */  apt /'
elif command -v dnf >/dev/null; then dnf -q list keyd 2>/dev/null | tail -n +2 | sed 's/^/  dnf /' || echo "  dnf: keyd not in enabled repos"
elif command -v pacman >/dev/null; then pacman -Si keyd 2>/dev/null | grep -E '^(Repository|Version)' | sed 's/^/  pacman /'
elif command -v zypper >/dev/null; then zypper -q se -x keyd 2>/dev/null | sed 's/^/  zypper /'
fi
echo "== Other remappers (can conflict with keyd)"
for t in kmonad kanata xremap interception toshy-config-start kinto input-remapper-service; do
  command -v $t >/dev/null && echo "  found: $t"
done
systemctl --user list-units --no-legend 2>/dev/null | grep -iE 'toshy|kinto|xremap' | sed 's/^/  user unit: /'
echo "== Terminals"; for t in ptyxis gnome-terminal konsole kitty alacritty wezterm foot xfce4-terminal tilix; do command -v $t >/dev/null && echo "  $t"; done
true
