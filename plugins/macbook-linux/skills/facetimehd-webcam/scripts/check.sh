#!/bin/bash
# Read-only: does this Mac have the FaceTime HD (PCIe) camera, and is it ready for the facetimehd driver?
echo "== Model: $(cat /sys/class/dmi/id/product_name 2>/dev/null)   Kernel: $(uname -r)"
if lspci -nn 2>/dev/null | grep -q '14e4:1570'; then
  echo "== Camera: $(lspci -nn | grep '14e4:1570')"
  lspci -k -d 14e4:1570 | grep -i 'driver in use' || echo "   no driver bound"
else
  echo "== No FaceTime HD PCIe camera (14e4:1570) found."
  echo "   USB cameras (older Macs, 'Apple Built-in iSight') work with uvcvideo; T2 Macs use apple-bce."
  lsusb 2>/dev/null | grep -iE 'apple.*(camera|isight)' ; exit 0
fi
echo "== Video devices:"; ls -l /dev/video* 2>/dev/null || echo "   none"
echo "== Already installed?"
dkms status -m facetimehd 2>/dev/null | sed 's/^/   /'
for d in /usr/lib/firmware/facetimehd /lib/firmware/facetimehd; do
  [ -f $d/firmware.bin ] && { echo "   firmware: $d/firmware.bin + $(ls $d/*_01XX.dat 2>/dev/null | wc -l) sensor files"; break; }
done
modinfo facetimehd 2>/dev/null | grep -E '^(filename|version)' | sed 's/^/   /'
echo "== Kernel modules claiming 14e4:1570 (anything besides facetimehd = an in-tree driver; prefer it)"
grep -i 'v000014E4d00001570' /lib/modules/$(uname -r)/modules.alias 2>/dev/null | awk '{print "   " $NF}' | sort -u
echo "== Build prerequisites"
[ -d /lib/modules/$(uname -r)/build ] && echo "   kernel headers: present" || echo "   kernel headers: MISSING"
for t in dkms make gcc git curl xz cpio; do printf '   %-5s %s\n' $t "$(command -v $t >/dev/null && echo ok || echo MISSING)"; done
command -v mokutil >/dev/null && echo "   secure boot: $(mokutil --sb-state 2>/dev/null)"
