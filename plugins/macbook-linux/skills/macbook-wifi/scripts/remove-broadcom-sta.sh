#!/bin/bash
# Remove the proprietary broadcom-sta (wl) driver when Wi-Fi already runs on the in-kernel brcmfmac.
# Run: sudo bash remove-broadcom-sta.sh   (then reboot)      Undo: sudo apt install broadcom-sta-dkms
set -euo pipefail
[[ $EUID -eq 0 ]] || { echo "Run with sudo"; exit 1; }
DEV=$(lspci -D -d 14e4: -nn | awk '/Network controller/{print $1; exit}')
DRV=$(lspci -k -s "$DEV" 2>/dev/null | awk -F': ' '/in use/{print $2}')
echo "Broadcom Wi-Fi: ${DEV:-none}  driver in use: ${DRV:-none}"
if [ "$DRV" != brcmfmac ] && [ "${1:-}" != --force ]; then
  echo "ERROR: Wi-Fi is not on brcmfmac. Removing wl could leave you without Wi-Fi. (--force to override)"; exit 1
fi
PKGS=$(dpkg-query -W -f='${Package} ${db:Status-Status}\n' 'broadcom-sta*' bcmwl-kernel-source 2>/dev/null | awk '$2=="installed"{print $1}')
if [ -n "$PKGS" ]; then apt-get purge -y $PKGS; else echo "No broadcom-sta / bcmwl packages installed."; fi
modprobe -r wl 2>/dev/null || true
echo "wl module present: $(modinfo -n wl 2>/dev/null || echo no)"
echo "RESULT: done - reboot, then check Wi-Fi"
