#!/bin/bash
# Build hci_uart from Ubuntu's own kernel source with the Apple BT wakeup patch.
# Usage: build.sh <kernelver> <kernel_source_dir>   (run by DKMS from its build dir)
set -euo pipefail
kver="$1"; kdir="$2"
base="${kver%%-*}"                     # 7.0.0-38-generic -> 7.0.0
abi="${kver%-*}"                       # 7.0.0-38-generic -> 7.0.0-38
tarball="/usr/src/linux-source-${base}/linux-source-${base}.tar.bz2"

if [[ ! -f "$tarball" ]]; then
    echo "ERROR: $tarball not found; install package linux-source-${base}" >&2
    exit 1
fi
srcver="$(dpkg-query -W -f='${Version}' "linux-source-${base}" 2>/dev/null || true)"
if [[ "$srcver" != "${abi}."* ]]; then
    echo "WARNING: linux-source-${base} is ${srcver:-unknown}, kernel is ${kver}; building anyway" >&2
fi

rm -rf src && mkdir src
tar -xjf "$tarball" -C src --strip-components=3 "linux-source-${base}/drivers/bluetooth"
patch -d src -p3 --forward < hci_bcm-apple-no-wakeup.patch

# Build only hci_uart; the object list comes from the kernel's own Makefile
# so CONFIG_BT_HCIUART_* options follow the target kernel's config.
{ echo 'obj-m := hci_uart.o'; grep -E '^hci_uart-' src/Makefile; } > src/Kbuild

make -C "$kdir" M="$PWD/src" modules
