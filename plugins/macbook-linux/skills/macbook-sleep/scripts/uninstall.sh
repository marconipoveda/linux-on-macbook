#!/bin/bash
# Remove everything install.sh and hibernate.sh added. Run: sudo bash uninstall.sh   (then reboot)
[[ $EUID -eq 0 ]] || { echo "Run with sudo"; exit 1; }
systemctl disable --now macbook-wakeup.service 2>/dev/null
rm -f /etc/systemd/system/macbook-wakeup.service /usr/local/sbin/macbook-wakeup \
      /usr/lib/systemd/system-sleep/50-macbook-sleep \
      /etc/udev/rules.d/90-macbook-nvme-no-d3cold.rules /etc/udev/rules.d/91-macbook-thunderbolt-no-d3cold.rules
rm -rf /etc/macbook-sleep
# hibernate.sh (the swap file itself is left alone)
rm -f /usr/lib/systemd/system-sleep/40-macbook-hibernate /etc/polkit-1/rules.d/10-macbook-allow-hibernate.rules \
      /etc/systemd/sleep.conf.d/90-macbook-hibernate.conf /etc/systemd/logind.conf.d/90-macbook-lid.conf \
      /etc/dracut.conf.d/90-macbook-resume.conf /etc/initramfs-tools/conf.d/90-macbook-resume
for f in /etc/default/grub.d/91-macbook-resume.cfg /etc/default/grub.d/92-macbook-no-recordfail-wait.cfg; do
  [ -f $f ] && rm -f $f && regrub=1
done
if [ -n "${regrub:-}" ]; then
  command -v update-grub >/dev/null && update-grub
  command -v update-initramfs >/dev/null && update-initramfs -u -k all
fi
if [ -f /etc/default/grub.d/90-macbook-mem-sleep.cfg ]; then
  rm -f /etc/default/grub.d/90-macbook-mem-sleep.cfg
  command -v update-grub >/dev/null && update-grub
fi
systemctl daemon-reload; udevadm control --reload
echo "Removed. Reboot to restore default sleep behaviour."
