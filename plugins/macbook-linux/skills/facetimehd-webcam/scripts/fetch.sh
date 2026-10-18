#!/bin/bash
# Download the driver source and build the firmware as the NORMAL user (no sudo).
# Usage: bash fetch.sh [workdir]   (default ~/facetimehd-build)
# Firmware is extracted from Apple's macOS 10.12.6 update: about 18 MB of byte ranges from
# updates.cdn-apple.com, hash-checked by upstream's script. Apple's firmware can't be
# redistributed, which is why every user builds it locally.
set -euo pipefail
W="${1:-$HOME/facetimehd-build}"
DRV_TAG="${DRV_TAG:-0.7.2}"           # tested 2026-10-18 on kernel 7.0; newer tags for newer kernels
FW_REF="${FW_REF:-60ee212}"           # facetimehd-firmware commit tested 2026-10-18 (firmware 5.60.0)
mkdir -p "$W"; cd "$W"
[ -d facetimehd-firmware ] || git clone https://github.com/patjak/facetimehd-firmware.git
git -C facetimehd-firmware checkout -q "$FW_REF"
# Upstream's Makefile streams byte ranges with curl into xzcat; a dropped connection shows up as
# "xzcat: Unexpected end of input". Retry a few times before giving up.
for try in 1 2 3; do
  make -C facetimehd-firmware && break
  [ $try = 3 ] && { echo "ERROR: firmware download failed 3 times (network?)"; exit 1; }
  echo "Download failed, retrying ($try/3)..."; rm -f facetimehd-firmware/AppleCamera*; sleep 5
done
rm -rf facetimehd
git clone -q --branch "$DRV_TAG" --depth 1 https://github.com/patjak/facetimehd.git
echo; ls -l facetimehd-firmware/firmware.bin; ls facetimehd-firmware/*_01XX.dat | wc -l | sed 's/^/sensor files: /'
echo "Driver: facetimehd $DRV_TAG in $W/facetimehd (don't run make in it; install.sh copies it to /usr/src)"
