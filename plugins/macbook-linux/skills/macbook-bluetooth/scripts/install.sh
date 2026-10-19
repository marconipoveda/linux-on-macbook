#!/bin/bash
# Install the patched hci_uart (Apple BTLP wake call removed) through DKMS. Ubuntu kernels (uses the linux-source-<version> .tar.bz2).
# Needs the linux-source package for the running kernel series (the script installs it).
# Run: sudo bash install.sh     then shut down fully, wait 10 s, power on (not a plain reboot)
set -euo pipefail
[[ $EUID -eq 0 ]] || { echo "Run with sudo"; exit 1; }
SRC="$(cd "$(dirname "$0")/../assets/apple-hci-uart-1.0" && pwd)"
NAME=apple-hci-uart; VER=1.0
KVER=$(uname -r); BASE=${KVER%%-*}
apt-get install -y dkms build-essential "linux-headers-$KVER" "linux-source-$BASE"
# Let DKMS build for the running kernel series only (a new series needs the patch re-checked)
SERIES=$(echo "$BASE" | cut -d. -f1,2 | sed 's/\./\\\\./')
if dkms status -m $NAME -v $VER | grep -q .; then dkms remove -m $NAME -v $VER --all; fi
rm -rf /usr/src/$NAME-$VER; cp -a "$SRC" /usr/src/$NAME-$VER; rm -rf /usr/src/$NAME-$VER/src
sed -i "s/^BUILD_EXCLUSIVE_KERNEL=.*/BUILD_EXCLUSIVE_KERNEL=\"^${SERIES}\\\\.\"/" /usr/src/$NAME-$VER/dkms.conf
grep BUILD_EXCLUSIVE /usr/src/$NAME-$VER/dkms.conf
dkms add -m $NAME -v $VER
dkms install -m $NAME -v $VER -k "$KVER"
echo "hci_uart now resolves to: $(modinfo -n hci_uart)"
modinfo -n hci_uart | grep -q /updates/dkms/ && echo "RESULT: OK - shut down fully, then power on" || echo "RESULT: patched module not picked up"
