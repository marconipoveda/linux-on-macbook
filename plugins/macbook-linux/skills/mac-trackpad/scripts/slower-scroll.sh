#!/bin/bash
# Slow down two-finger scrolling by telling libinput the touchpad has a higher resolution
# (hwdb override). GNOME has no scroll-speed setting. This also slows the pointer by the same
# factor; compensate afterwards with the normal pointer speed setting.
#
# Usage: sudo bash slower-scroll.sh [factor]     factor 2 = half the scroll speed (default)
#        sudo bash slower-scroll.sh --remove     undo
# Takes effect after a reboot (libinput only reads these properties when the device appears).
set -euo pipefail
[[ $EUID -eq 0 ]] || { echo "Run with sudo"; exit 1; }
HWDB=/etc/udev/hwdb.d/61-macbook-touchpad-scroll.hwdb
echo "== $(date)"

if [ "${1:-}" = "--remove" ]; then
  rm -f "$HWDB"; systemd-hwdb update; echo "Removed. Reboot to apply."; exit 0
fi
FACTOR="${1:-2}"

# Find the touchpad's event node and name
IFS=$'\t' read -r NAME EV < <(awk -v RS= '/Name="[^"]*([Tt]ouchpad|[Tt]rackpad)/ && /Handlers=[^\n]*mouse/ {
    match($0,/Name="[^"]*"/); n=substr($0,RSTART+6,RLENGTH-7)
    match($0,/event[0-9]+/); print n "\t" substr($0,RSTART,RLENGTH); exit}' /proc/bus/input/devices)
[ -n "${EV:-}" ] || { echo "ERROR: no touchpad found"; exit 1; }
echo "touchpad: $NAME (/dev/input/$EV)"

# Original resolutions: from our earlier override if present (current values would already be scaled)
if [ -f "$HWDB" ]; then
  ORIG=$(grep -oP '(?<=# original: ).*' "$HWDB")
else
  # systemd's own hwdb usually already sets these for Apple trackpads (60-evdev.hwdb)
  ORIG=$(udevadm info "/dev/input/$EV" | sed -nE 's/^E: EVDEV_ABS_(00|01|35|36)=::([0-9]+)$/\1=\2/p' | tr '\n' ' ')
fi
if [ -z "$ORIG" ]; then
  ORIG=$(python3 -I - "/dev/input/$EV" <<'PY'
import fcntl, struct, sys
fd = open(sys.argv[1], 'rb')
out = []
for code in (0x00, 0x01, 0x35, 0x36):          # ABS_X, ABS_Y, ABS_MT_POSITION_X, ABS_MT_POSITION_Y
    buf = bytearray(24)
    try:
        fcntl.ioctl(fd, 0x80184540 + code, buf)  # EVIOCGABS(code)
        out.append("%02X=%d" % (code, struct.unpack('6i', buf)[5]))
    except OSError:
        pass
print(" ".join(out))
PY
)
fi
echo "original resolutions (units/mm): $ORIG"
case "$ORIG" in *=0*|"") echo "ERROR: touchpad reports no resolution; this method doesn't apply"; exit 1 ;; esac

{
  echo "# Slower two-finger scrolling (factor $FACTOR). Written by slower-scroll.sh (mac-trackpad skill)"
  echo "# original: $ORIG"
  echo "evdev:name:$NAME:*"
  for kv in $ORIG; do
    code=${kv%%=*}; res=${kv#*=}
    echo " EVDEV_ABS_$code=::$(python3 -c "print(round($res*$FACTOR))")"
  done
} > "$HWDB"
cat "$HWDB"
systemd-hwdb update
echo "Installed. REBOOT now, then adjust pointer speed (scrolling is $FACTOR x slower)."
