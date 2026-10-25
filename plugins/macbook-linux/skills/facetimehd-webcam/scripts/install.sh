#!/bin/bash
# Install FaceTime HD firmware + the facetimehd driver through DKMS (rebuilds on kernel updates).
# Run fetch.sh first, then:  sudo bash install.sh [workdir]   (default: ~/facetimehd-build of the sudo user)
set -euo pipefail
[[ $EUID -eq 0 ]] || { echo "Run with sudo"; exit 1; }
U="${SUDO_USER:-root}"; UH=$(getent passwd "$U" | cut -d: -f6)
W="$(readlink -f "${1:-$UH/facetimehd-build}")"
[ -f "$W/facetimehd-firmware/firmware.bin" ] || { echo "ERROR: run fetch.sh first ($W)"; exit 1; }
[ -f "$W/facetimehd/dkms.conf" ] || { echo "ERROR: driver source missing in $W/facetimehd"; exit 1; }
LOG="$W/install.log"
{
echo "== $(date)  kernel $(uname -r)"
# Build dependencies
if command -v apt-get >/dev/null; then apt-get install -y dkms build-essential "linux-headers-$(uname -r)"
elif command -v dnf >/dev/null; then dnf install -y dkms gcc make "kernel-devel-$(uname -r)"
elif command -v pacman >/dev/null; then pacman -S --needed --noconfirm dkms base-devel linux-headers
fi

make -C "$W/facetimehd-firmware" install          # -> /usr/lib/firmware/facetimehd/

V=$(git -C "$W/facetimehd" describe --tags 2>/dev/null || echo 0.0.0)
for old in $(dkms status -m facetimehd 2>/dev/null | sed -E 's#^facetimehd/([^,:]+).*#\1#' | sort -u); do
  dkms remove -m facetimehd -v "$old" --all || true
done
rm -rf "/usr/src/facetimehd-$V"; mkdir "/usr/src/facetimehd-$V"
cp -r "$W/facetimehd/"* "/usr/src/facetimehd-$V/"
# Upstream dkms.conf has a stale PACKAGE_VERSION and a MODULES_CONF line (blacklisting bdc_pci,
# removed in Linux 5.12) that newer DKMS rejects.
sed -i -e "s/^PACKAGE_VERSION=.*/PACKAGE_VERSION=$V/" -e '/^MODULES_CONF/d' "/usr/src/facetimehd-$V/dkms.conf"
dkms add -m facetimehd -v "$V"
dkms install -m facetimehd -v "$V" -k "$(uname -r)"

modprobe -r facetimehd 2>/dev/null || true
modprobe facetimehd
sleep 3
echo "== kernel log"; journalctl -k --since "-1min" --no-pager | grep -iE 'facetimehd|fthd' | tail -n 15 || true
echo "== video devices"; ls -l /dev/video* || true
dkms status -m facetimehd
# Capture first: with pipefail, `journalctl | grep -q` fails when grep exits early (SIGPIPE).
klog=$(journalctl -k --since "-1min" --no-pager)
if ls /dev/video* >/dev/null 2>&1 && grep -q 'Loaded firmware' <<<"$klog"; then
  echo "RESULT: OK"
else
  echo "RESULT: driver installed but no camera yet (reboot once, then check again)"
fi
} 2>&1 | tee "$LOG"
chown "$U": "$LOG" 2>/dev/null || true
