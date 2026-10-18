#!/bin/bash
# Generate a keyd config from the template.
# Usage: make-config.sh <gnome|kde|other> [--both-option-keys] > mac-keys.conf
#   --both-option-keys : also give Right Option the Mac text-navigation layer.
#                        Only for US-style layouts; on es/latam/de/fr/... Right Option is AltGr
#                        and is needed to type @ # [ ] { } etc.
set -e
DESKTOP="${1:-}"; BOTH=0
[ "$2" = "--both-option-keys" ] && BOTH=1
case "$DESKTOP" in
  gnome)  # GNOME: Super+Tab = switch-applications, Super+` = switch-group, Super+H = minimize
    SW=M; SPACE="M-space"; MIN=$'h = M-h\nm = M-h' ;;
  kde)    # Plasma: Alt+Tab / Alt+` walk windows, Alt+Space = KRunner, Meta+PgDown = minimize
    SW=A; SPACE="A-space"; MIN=$'h = M-pagedown\nm = M-pagedown' ;;
  other)  # XFCE, Cinnamon, MATE, Budgie...: Alt+Tab, tapping Super opens the menu, no standard minimize
    SW=A; SPACE="leftmeta"; MIN="# Cmd+H / Cmd+M: no standard minimize shortcut on this desktop, left as Ctrl+H / Ctrl+M" ;;
  *) echo "usage: $0 <gnome|kde|other> [--both-option-keys]" >&2; exit 1 ;;
esac
if [ $BOTH = 1 ]; then RA="rightalt = layer(opt)"; else RA="# rightalt untouched (AltGr)"; fi
TEMPLATE="$(cd "$(dirname "$0")/.." && pwd)/assets/mac-keys.conf.in"
while IFS= read -r line; do
  case "$line" in
    @MINIMIZE@) printf '%s\n' "$MIN" ;;
    @RIGHTALT@) printf '%s\n' "$RA" ;;
    *) line="${line//@SW@/$SW}"; line="${line//@SPACE@/$SPACE}"; line="${line//@DESKTOP@/$DESKTOP}"
       printf '%s\n' "$line" ;;
  esac
done < "$TEMPLATE"
