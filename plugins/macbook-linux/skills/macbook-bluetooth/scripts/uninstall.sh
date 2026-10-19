#!/bin/bash
# Remove the patched hci_uart; the stock driver returns after a reboot. Run: sudo bash uninstall.sh
[[ $EUID -eq 0 ]] || { echo "Run with sudo"; exit 1; }
dkms remove -m apple-hci-uart -v 1.0 --all; rm -rf /usr/src/apple-hci-uart-1.0; depmod -a
echo "Removed. Reboot."
