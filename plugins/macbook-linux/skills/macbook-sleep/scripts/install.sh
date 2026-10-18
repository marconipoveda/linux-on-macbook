#!/bin/bash
# Install suspend/resume fixes for Macs. Root required; the person runs it in their own terminal.
# Apply ONE fix at a time and test a suspend before adding the next.
#
#   sudo bash install.sh --nvme                     keep Apple NVMe SSDs out of D3cold (resume hangs otherwise)
#   sudo bash install.sh --thunderbolt              keep Thunderbolt NHI/xHCI out of D3cold (60 s+ resume)
#   sudo bash install.sh --wake "XHC1 XHC2 ..."     disable these ACPI wake sources at boot and after resume
#                        [--keep "LID0 EC"]         ...and make sure these stay enabled
#   sudo bash install.sh --s2idle                   default to s2idle instead of deep (S3); needs reboot
#   sudo bash install.sh --applespi-hook            reload applespi after resume (garbled trackpad)
#   sudo bash install.sh --status                   show what is installed
set -euo pipefail
[[ $EUID -eq 0 ]] || { echo "Run with sudo"; exit 1; }
[ $# -gt 0 ] || { sed -n 2,12p "$0"; exit 1; }
CONF=/etc/macbook-sleep/wakeup.conf
HOOK=/usr/lib/systemd/system-sleep/50-macbook-sleep
WAKE_BIN=/usr/local/sbin/macbook-wakeup

write_wake_bin() {
  mkdir -p /etc/macbook-sleep
  [ -f $CONF ] || printf '# ACPI wake sources (names from /proc/acpi/wakeup). Applied at boot and after every resume.\nDISABLE=""\nENABLE=""\n' > $CONF
  cat > $WAKE_BIN <<'W'
#!/bin/sh
# Apply /etc/macbook-sleep/wakeup.conf. Writing a name to /proc/acpi/wakeup TOGGLES it,
# so only write when the current state differs.
. /etc/macbook-sleep/wakeup.conf
set_wake() {
    grep -qE "^$1[[:space:]]" /proc/acpi/wakeup || return 0
    grep -qE "^$1[[:space:]].*\*$2" /proc/acpi/wakeup || echo "$1" > /proc/acpi/wakeup
}
for d in $DISABLE; do set_wake "$d" disabled; done
for d in $ENABLE;  do set_wake "$d" enabled;  done
exit 0
W
  chmod 755 $WAKE_BIN
  cat > /etc/systemd/system/macbook-wakeup.service <<W
[Unit]
Description=Mac: limit ACPI wake sources (/etc/macbook-sleep/wakeup.conf)

[Service]
Type=oneshot
ExecStart=$WAKE_BIN

[Install]
WantedBy=multi-user.target
W
  systemctl daemon-reload; systemctl enable macbook-wakeup.service
}

write_hook() {   # one hook for everything that must run after resume
  cat > $HOOK <<'H'
#!/bin/sh
# Mac suspend/resume workarounds (macbook-sleep skill). $1 = pre|post
case "$1" in
    post)
        # Optional: SPI trackpad can return garbled; reloading applespi re-initialises it.
        [ -f /etc/macbook-sleep/applespi-reload ] && lsmod | grep -q '^applespi' && { modprobe -r applespi && modprobe applespi; }
        # Re-apply wake sources (driver reloads re-enable their own wake flags)
        [ -x /usr/local/sbin/macbook-wakeup ] && /usr/local/sbin/macbook-wakeup
        ;;
esac
exit 0
H
  chmod 755 $HOOK
}

while [ $# -gt 0 ]; do case "$1" in
  --nvme)
    # Apple NVMe controllers: 106b:2001 (S1X, 12" MacBook) and 106b:2003 (S3X, 2016-2017 MacBook Pro).
    # Apple reports a non-standard PCI class (0x018002), so match by ID, not by NVMe class.
    # Documented on MacBookPro13,x/14,x by the mbp-2016-linux project; verified on MacBookPro13,1.
    echo 'ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x106b", ATTR{device}=="0x2001|0x2003", ATTR{d3cold_allowed}="0"'       > /etc/udev/rules.d/90-macbook-nvme-no-d3cold.rules
    udevadm control --reload
    for d in /sys/bus/pci/devices/*; do
      [ "$(cat $d/vendor)" = 0x106b ] || continue
      case "$(cat $d/device)" in 0x2001|0x2003) echo 0 > $d/d3cold_allowed; echo "NVMe $(basename $d): d3cold_allowed=0" ;; esac
    done ;;
  --thunderbolt)
    # Intel Thunderbolt host controllers (NHI, PCI class 0x088000) and the Thunderbolt USB controllers
    # (Alpine Ridge 15b5/15b6/15c1/15d4/15db, Titan Ridge 15e9/15ec/15f0). Keeping them out of D3cold
    # keeps their parent TB bridges in D0. Verified on MacBookPro13,1 (NHI 15d2, xHCI 15d4).
    cat > /etc/udev/rules.d/91-macbook-thunderbolt-no-d3cold.rules <<'R'
ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x8086", ATTR{class}=="0x088000", ATTR{d3cold_allowed}="0"
ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x8086", ATTR{device}=="0x15b5|0x15b6|0x15c1|0x15d4|0x15db|0x15e9|0x15ec|0x15f0", ATTR{d3cold_allowed}="0"
R
    udevadm control --reload; echo "Thunderbolt rule installed (takes effect after reboot)" ;;
  --wake)
    write_wake_bin; sed -i "s/^DISABLE=.*/DISABLE=\"$2\"/" $CONF; shift; write_hook
    systemctl restart macbook-wakeup.service ;;
  --keep)
    write_wake_bin; sed -i "s/^ENABLE=.*/ENABLE=\"$2\"/" $CONF; shift; write_hook
    systemctl restart macbook-wakeup.service ;;
  --s2idle)
    mkdir -p /etc/default/grub.d
    printf '# macbook-sleep: deep (S3) does not resume reliably on this Mac; use s2idle.\nGRUB_CMDLINE_LINUX_DEFAULT="$GRUB_CMDLINE_LINUX_DEFAULT mem_sleep_default=s2idle"\n' \
      > /etc/default/grub.d/90-macbook-mem-sleep.cfg
    if command -v update-grub >/dev/null; then update-grub
    elif command -v grub2-mkconfig >/dev/null; then grub2-mkconfig -o /boot/grub2/grub.cfg
    elif command -v grub-mkconfig >/dev/null; then grub-mkconfig -o /boot/grub/grub.cfg
    else echo "No GRUB found: add mem_sleep_default=s2idle to your bootloader's kernel command line"; fi
    echo s2idle > /sys/power/mem_sleep; echo "s2idle active now and after reboot" ;;
  --applespi-hook)
    mkdir -p /etc/macbook-sleep; touch /etc/macbook-sleep/applespi-reload; write_hook; echo "applespi reload after resume: on" ;;
  --status) ;;
  *) echo "unknown option: $1"; exit 1 ;;
esac; shift; done

echo "---- status"
echo "mem_sleep: $(cat /sys/power/mem_sleep)"
ls /etc/udev/rules.d/9?-macbook-* 2>/dev/null
[ -f $CONF ] && grep -v '^#' $CONF
[ -f /etc/macbook-sleep/applespi-reload ] && echo "applespi-reload: on"
echo "enabled wake sources:"; grep enabled /proc/acpi/wakeup | awk '{print "  " $1}'
