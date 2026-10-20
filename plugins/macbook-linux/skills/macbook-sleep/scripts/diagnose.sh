#!/bin/bash
# Read-only suspend/resume diagnosis for Macs running Linux. No root needed.
echo "== Model: $(cat /sys/class/dmi/id/product_name 2>/dev/null)   Kernel: $(uname -r)"
echo "== Sleep modes (bracket = current): $(cat /sys/power/mem_sleep 2>/dev/null)"
grep -o 'mem_sleep_default=[a-z0-9]*' /proc/cmdline | sed 's/^/   cmdline: /'
echo "== Lid handling"
grep -hE '^\s*Handle(LidSwitch|LidSwitchExternalPower|LidSwitchDocked)' /etc/systemd/logind.conf /etc/systemd/logind.conf.d/*.conf 2>/dev/null | sed 's/^/   /'
echo "== ACPI wake sources (enabled ones)"; grep enabled /proc/acpi/wakeup 2>/dev/null | sed 's/^/   /'
echo "== Storage"
for d in /sys/bus/pci/devices/*; do
  c=$(cat $d/class 2>/dev/null); v=$(cat $d/vendor 2>/dev/null)
  [ "$c" = 0x010802 ] || { [ "$v" = 0x106b ] && [ "${c:0:4}" = 0x01 ]; } || continue   # NVMe (Apple uses class 0x018002)
  echo "   NVMe $(basename $d) $(cat $d/vendor):$(cat $d/device) d3cold_allowed=$(cat $d/d3cold_allowed 2>/dev/null)"
done
lsblk -dno NAME,TRAN,MODEL -e 7 2>/dev/null | sed 's/^/   /'
echo "== Thunderbolt / USB-C controllers"
lspci -nn 2>/dev/null | grep -iE 'thunderbolt|JHL|DSL' | while read -r l; do
  a=${l%% *}; echo "   $l  d3cold_allowed=$(cat /sys/bus/pci/devices/0000:$a/d3cold_allowed 2>/dev/null)"; done
echo "== Keyboard/trackpad driver: $(lsmod | awk '$1~/^(applespi|bcm5974|hid_apple|apple_bce)$/{printf "%s ", $1}')"
echo "== Installed sleep hooks / services"
ls /usr/lib/systemd/system-sleep/ 2>/dev/null | sed 's/^/   hook: /'
ls /etc/udev/rules.d/ 2>/dev/null | grep -iE 'd3cold|apple|macbook' | sed 's/^/   udev: /'
systemctl is-enabled macbook-wakeup.service 2>/dev/null | sed 's/^/   macbook-wakeup.service: /'
[ -f /etc/macbook-sleep/wakeup.conf ] && sed 's/^/   wakeup.conf: /' /etc/macbook-sleep/wakeup.conf | grep -v '^   wakeup.conf: #'
echo "== Past suspends (did each boot end on a suspend? that means resume failed)"
for b in -4 -3 -2 -1; do
  last=$(journalctl -b $b -o cat --no-pager 2>/dev/null | grep -E 'PM: suspend (entry|exit)' | tail -n1)
  [ -n "$last" ] && echo "   boot $b: last PM line: $last"
done
journalctl -b 0 -o short-monotonic --no-pager 2>/dev/null | grep -E 'PM: suspend (entry|exit)|ACPI: PM: Waking up from system sleep|Wakeup from|applespi: Received corrupted' | tail -n 12 | sed 's/^/   this boot: /'
echo "== Slow resume devices (this boot)"
journalctl -b 0 -k --no-pager 2>/dev/null | grep -E 'Refused to change power state|D3cold to D0|device inaccessible|PM: .* took [0-9]{4,}' | tail -n 8 | sed 's/^/   /'
echo "== Hibernation"
echo "   resume device: $(cat /sys/power/resume 2>/dev/null) offset $(cat /sys/power/resume_offset 2>/dev/null)   swap: $(swapon --show=NAME,SIZE --noheadings 2>/dev/null | tr -s ' ' | paste -sd,)"
for a in CanHibernate CanSuspendThenHibernate; do
  echo "   logind $a: $(busctl call org.freedesktop.login1 /org/freedesktop/login1 org.freedesktop.login1.Manager $a 2>/dev/null | awk '{print $2}')"
done
journalctl -b 0 -o cat --no-pager 2>/dev/null | grep -E 'Image not found|Hibernation image restored|Failed to load image|quiesce of devices aborted|freeze of devices aborted' | tail -n 4 | sed 's/^/   /'
