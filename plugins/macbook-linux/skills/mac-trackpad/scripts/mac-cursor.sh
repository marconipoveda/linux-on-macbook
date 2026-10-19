#!/bin/bash
# Install a macOS-style cursor theme for the current user (no sudo) and switch GNOME to it.
# Theme: apple_cursor by ful1e5 (GPL-3.0), an open-source recreation, not Apple's files.
# Usage: bash mac-cursor.sh [macOS|macOS-White] [size]      e.g. bash mac-cursor.sh macOS 24
set -euo pipefail
THEME="${1:-macOS}"; SIZE="${2:-}"
VER=v2.0.1; URL=https://github.com/ful1e5/apple_cursor/releases/download/$VER/macOS.tar.xz
EXPECTED_SIZE=5514788                       # bytes of the v2.0.1 asset
DEST="${XDG_DATA_HOME:-$HOME/.local/share}/icons"
TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT

curl -fsSL --retry 3 -o "$TMP/macOS.tar.xz" "$URL"
[ "$(stat -c %s "$TMP/macOS.tar.xz")" = $EXPECTED_SIZE ] || { echo "ERROR: unexpected download size"; exit 1; }
xz -t "$TMP/macOS.tar.xz"
# Refuse archives with absolute paths or ..
tar -tJf "$TMP/macOS.tar.xz" | grep -qE '^/|(^|/)\.\.(/|$)' && { echo "ERROR: unsafe paths in archive"; exit 1; }
tar -xJf "$TMP/macOS.tar.xz" -C "$TMP" ./macOS ./macOS-White
find "$TMP/macOS" "$TMP/macOS-White" -type l -printf '%l\n' | grep -qE '^/|\.\.' && { echo "ERROR: unsafe symlinks"; exit 1; }

mkdir -p "$DEST"; rm -rf "$DEST/macOS" "$DEST/macOS-White"
cp -a "$TMP/macOS" "$TMP/macOS-White" "$DEST/"

if command -v gsettings >/dev/null && gsettings writable org.gnome.desktop.interface cursor-theme >/dev/null 2>&1; then
  U=~/.config/mac-trackpad; mkdir -p $U
  [ -f $U/undo-cursor.sh ] || echo "gsettings set org.gnome.desktop.interface cursor-theme $(gsettings get org.gnome.desktop.interface cursor-theme)" > $U/undo-cursor.sh
  gsettings set org.gnome.desktop.interface cursor-theme "$THEME"
  [ -n "$SIZE" ] && gsettings set org.gnome.desktop.interface cursor-size "$SIZE"
  echo "Cursor theme: $(gsettings get org.gnome.desktop.interface cursor-theme), size $(gsettings get org.gnome.desktop.interface cursor-size)"
  echo "Undo: bash $U/undo-cursor.sh   (restart browsers, or log out/in, if an app keeps the old cursor)"
else
  echo "Installed to $DEST. Select \"$THEME\" in your desktop's cursor settings."
fi
