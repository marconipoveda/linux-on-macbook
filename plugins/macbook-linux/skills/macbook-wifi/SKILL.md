---
name: macbook-wifi
description: Check and clean up Wi-Fi on Linux on Intel MacBooks with Broadcom chips (BCM4350, BCM4360, BCM43602 and similar). Covers which driver should own the card (in-kernel brcmfmac vs the proprietary broadcom-sta/wl), removing a conflicting wl driver that crashes at boot, missing board-specific firmware files, and Wi-Fi that sometimes doesn't come up after a reboot. Use this whenever someone on Linux on a Mac has Wi-Fi that fails intermittently, sees wl or brcmfmac errors in the kernel log, has both broadcom-sta and brcmfmac installed, or asks which Broadcom driver to use. Also relevant when Bluetooth and Wi-Fi fail together, since they're often one chip.
---

# Wi-Fi on Intel Macs (Broadcom)

## 1. Which driver owns the card?

```bash
lspci -k -d 14e4: | grep -A3 -i network     # "Kernel driver in use"
dpkg -l | grep -E 'broadcom-sta|bcmwl'
journalctl -k -b | grep -iE 'brcmfmac|wl_|\[wl\]'
```

- **brcmfmac** (in-kernel, open source) supports most Mac chips from ~2015 on: BCM4350, BCM43602, BCM4364 (T2 with t2linux firmware). If Wi-Fi works on brcmfmac, it should be the only Broadcom driver.
- **broadcom-sta / wl** (proprietary, unmaintained) is only needed for older chips that brcmfmac doesn't support, such as BCM4360 (`14e4:43a0`) in many 2013–2014 Macs. Check the PCI ID before removing anything.

## 2. Remove a conflicting wl driver

The symptom: the kernel log shows `wl_module_init` with a WARNING/Call Trace and `ERROR @wl_cfg80211_detach` on every boot, while Wi-Fi works on brcmfmac. The proprietary driver loads, fails, and touches the chip first. On MacBookPro13,1 this coincided with a boot where both Wi-Fi (`brcmfmac: brcmf_chip_recognition: MMIO read failed: 0xffffffff`) and Bluetooth failed, because they're the same BCM4350 chip.

```bash
sudo bash scripts/remove-broadcom-sta.sh     # refuses unless brcmfmac is the driver in use; then reboot
```

It purges only the broadcom-sta/bcmwl packages actually installed (their modprobe blacklists go with them). Undo: `sudo apt install broadcom-sta-dkms`. After the reboot, check that the `wl` lines are gone and the interface is up (`ip -br link`).

## 3. Missing firmware messages

`Direct firmware load for brcm/brcmfmac4350c2-pcie.Apple Inc.-MacBookPro13,1.txt / .clm_blob / .txcap_blob failed with error -2` is normal on Macs. These board-specific NVRAM and regulatory files aren't in linux-firmware. Wi-Fi works with the generic firmware, sometimes with fewer channels or lower transmit power. The real files come from macOS (`/usr/share/firmware/wifi` on a macOS install). Mention that as an optional improvement, and don't download them from random sites.

## 4. Bluetooth audio and 2.4 GHz

On combo chips, Bluetooth and 2.4 GHz Wi-Fi share the radio. If the person uses Bluetooth audio, prefer the router's 5 GHz network (`iw dev <wlan> link | grep freq`). See the macbook-bluetooth skill.
