#!/bin/bash
# Test: when Bluetooth failed at boot, does reloading the driver bring it back without a reboot?
# Run ONLY in a boot where Bluetooth failed:  sudo bash retry-bt.sh
set -u
[[ $EUID -eq 0 ]] || { echo "Run with sudo"; exit 1; }
{
echo "== $(date)"
for try in 1 2 3; do
  echo "-- attempt $try"
  systemctl stop bluetooth
  rmmod hci_uart 2>/dev/null; sleep 2
  modprobe hci_uart; sleep 6
  systemctl start bluetooth; sleep 3
  journalctl -k --since "-15s" --no-pager | grep -E 'hci0' | tail -4
  if timeout 5 bluetoothctl show 2>/dev/null | grep -q 'Powered: yes'; then echo "RESULT: recovered on attempt $try"; break; fi
done
timeout 5 bluetoothctl show 2>/dev/null | grep -E 'Controller|Powered' || echo "RESULT: still no controller"
} 2>&1
