---
name: macbook-bluetooth
description: Fix and troubleshoot Bluetooth on Linux on Intel MacBooks, especially the 2016–2017 MacBook Pro without Touch Bar (MacBookPro13,1 / 14,1) whose Broadcom UART Bluetooth often fails at boot ("hci0 command 0xfc18 tx timeout", "No default controller", address 00:00:00:00:00:00). Also covers Bluetooth speakers and headphones that won't play, play choppy or cut out, or show as "connected" but give no sound. Use this whenever someone on Linux on a Mac says Bluetooth doesn't work, doesn't appear after boot, works only sometimes, or their Bluetooth audio device misbehaves.
---

# Bluetooth on Intel Macs

Two kinds of problem show up here, and they need very different fixes:
1. **The controller doesn't come up**: kernel and driver level, needs root, takes several boots to verify.
2. **The controller is fine, but an audio device misbehaves**: connection state, profiles and radio sharing. User-level and quick. See `references/audio.md`.

Tell them apart first: `timeout 5 bluetoothctl show`. A `Controller <real address>` with `Powered: yes` means case 2.

## 1. Measure before fixing

On MacBookPro13,1 the stock driver was **intermittent**, not dead: across 35 logged boots it failed in about 1 of 3, more often after a warm reboot (7 of 16) than after a full power-off (2 of 8). One good or bad boot proves nothing, so count:

```bash
bash scripts/check-boots.sh                       # every logged boot: ok / FAIL / -
bash scripts/check-boots.sh "2026-10-18 18:40"    # only boots since a change
```

A FAIL boot logs `hci0: command 0xfc18 tx timeout` and `BCM: failed to write update baudrate (-110)`. `BCM: firmware Patch file not found` is normal: the chip runs from ROM, and no `.hcd` is needed.

Also check for the proprietary **`broadcom-sta` (`wl`)** driver: `dpkg -l | grep broadcom-sta`. The Wi-Fi and Bluetooth are one BCM4350 chip, and `wl` crashes on these models and can leave the chip unresponsive for both. In the one boot where both Wi-Fi and Bluetooth failed, `wl` had crashed first. Remove it first with the macbook-wifi skill, if Wi-Fi already runs on `brcmfmac`.

## 2. The patched driver (Ubuntu)

Known kernel bug (kernel bugzilla 205115, Dunedan/mbp-2016-linux #29): `hci_bcm.c` calls `set_device_wakeup()`, which runs Apple's ACPI `BTLP` method, and on these models that can leave the chip unresponsive. The community fix removes the call. `assets/apple-hci-uart-1.0/` is a DKMS package that extracts `drivers/bluetooth` from Ubuntu's own `linux-source-<version>` package (a `.tar.bz2`; Debian ships its source differently, so use the leifliddy package there), applies the patch, and builds only `hci_uart`.

```bash
sudo bash scripts/install.sh    # then shut down completely, wait 10 s, power on
```

- It pins DKMS to the running kernel series. When the distro moves to a new series (e.g. 7.0 → 7.1), DKMS skips the module and the stock driver comes back. To refresh: re-run install.sh on the new kernel. If `patch` fails there, upstream has changed the code; read the current `bcm_gpio_set_power()` before adapting the patch.
- Check it's loaded: `modinfo -n hci_uart` should point into `/updates/dkms/`, and `cat /sys/module/hci_uart/srcversion` should equal `modinfo -F srcversion hci_uart`.
- Other distros: [leifliddy/macbook12-bluetooth-driver](https://github.com/leifliddy/macbook12-bluetooth-driver) applies the same patch against kernel.org sources. Use one or the other, never both.
- Undo: `sudo bash scripts/uninstall.sh`, then reboot.

**Be honest about results.** On MacBookPro13,1 the patch reduced failures but didn't make them disappear (first 6 boots: 5 ok, 1 fail, and that one failure coincided with a `wl` crash; 3 of 3 ok since `wl` was removed). Report counts, not "fixed", until at least 5–10 boots in a row come up clean.

## 3. When a boot fails anyway

Before rebooting, run `sudo bash scripts/retry-bt.sh`. It reloads `hci_uart` up to 3 times and reports whether the controller came back. This tells you whether a boot-time retry service would be a reliable workaround: if reloads recover it, a oneshot unit that runs after `bluetooth.service` can do the same automatically. If they don't, only a full power-off resets the chip; tell the person that, as the practical workaround.

## 4. Audio devices

See `references/audio.md`: "connected" but no sound, choppy audio, and auto-reconnect. Common points: the GNOME button shows the *action* ("Connect" = currently disconnected); a speaker refusing playback with `Stream End Point in Use` needs a reconnect; and **2.4 GHz Wi-Fi shares the chip and antenna with Bluetooth**, so moving Wi-Fi to 5 GHz is the biggest single fix for stutter.
