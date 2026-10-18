#!/bin/bash
# Remove the facetimehd DKMS driver, firmware and optional sleep hook. Run: sudo bash uninstall.sh [--keep-firmware]
[[ $EUID -eq 0 ]] || { echo "Run with sudo"; exit 1; }
modprobe -r facetimehd 2>/dev/null
for v in $(dkms status -m facetimehd 2>/dev/null | sed -E 's#^facetimehd/([^,:]+).*#\1#' | sort -u); do
  dkms remove -m facetimehd -v "$v" --all; rm -rf "/usr/src/facetimehd-$v"
done
[ "$1" = "--keep-firmware" ] || rm -rf /usr/lib/firmware/facetimehd
rm -f /usr/lib/systemd/system-sleep/99facetimehd
echo "facetimehd removed"
