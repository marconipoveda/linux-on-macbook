#!/bin/bash
# Remove everything install.sh added. Run: sudo bash uninstall.sh   (then reboot)
[[ $EUID -eq 0 ]] || { echo "Run with sudo"; exit 1; }
systemctl disable --now macbook-wakeup.service 2>/dev/null
rm -f /etc/systemd/system/macbook-wakeup.service /usr/local/sbin/macbook-wakeup \
      /usr/lib/systemd/system-sleep/50-macbook-sleep \
      /etc/udev/rules.d/90-macbook-nvme-no-d3cold.rules /etc/udev/rules.d/91-macbook-thunderbolt-no-d3cold.rules
rm -rf /etc/macbook-sleep
if [ -f /etc/default/grub.d/90-macbook-mem-sleep.cfg ]; then
  rm -f /etc/default/grub.d/90-macbook-mem-sleep.cfg
  command -v update-grub >/dev/null && update-grub
fi
systemctl daemon-reload; udevadm control --reload
echo "Removed. Reboot to restore default sleep behaviour."
