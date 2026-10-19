# MacBookPro13,1 — MacBook Pro 13" Late 2016 (two Thunderbolt 3 ports, function keys)

Last scanned: 2026-10-18 · Distro: Ubuntu 26.04.1 LTS · Kernel: 7.0.0-38-generic · Desktop: GNOME 50 (Wayland)

## Device status

Legend: ✅ works out of the box · 🔧 works after a fix (linked) · ⚠️ partial · ❌ not working · ❔ untested

| Component | Hardware (PCI/USB/ACPI ID) | Driver | Status | Notes / fix |
|---|---|---|---|---|
| CPU | Intel Core i5-6360U (Skylake) | intel_pstate (HWP) | ✅ | |
| GPU | Intel Iris Graphics 540 `8086:1926` | i915 | ✅ | |
| Display / backlight | 2560×1600 eDP | i915, acpi_video | ⚠️ | Backlight runs through `acpi_video0` (0–90), not `intel_backlight` |
| Storage | Apple SSD AP0256J, NVMe `106b:2003` | nvme | ✅ | Must stay out of D3cold for sleep to work, see Suspend |
| Keyboard | Apple SPI Keyboard (ACPI APP000D) | applespi | ✅ | Mac-style shortcuts: 🔧 [mac-keyboard-shortcuts](../plugins/macbook-linux/skills/mac-keyboard-shortcuts) |
| Trackpad | Apple SPI Force Touch | applespi | 🔧 | Mac-style via [mac-trackpad](../plugins/macbook-linux/skills/mac-trackpad): tap-to-click off, two-finger right-click, scroll factor 2 (hwdb), adaptive at speed 0.4, macOS cursor. No haptics. Can come back garbled after resume until `applespi` is reloaded (fixed by the sleep hook) |
| Keyboard backlight | `spi::kbd_backlight` | applespi | ✅ | |
| Audio (speakers / mic / jack) | Cirrus Logic CS8409 / CS42L83 | snd_hda_codec_cs8409 | ⚠️ | Verified 2026-10-18 on kernel 7.0: both speakers (correct left/right), internal mic, and **headphone output** (auto-switch on plug-in) work. **Headset mic does not**: it's detected, but records pure digital silence, because the kernel driver can't enable its capture switch (`patch_cs8409 NOT FOUND trying APPLE`, generic fallback). Workarounds: a **USB headset works fully**: Apple EarPods (USB-C, `05ac:110b`) tested, with left/right output and a clear mic via snd-usb-audio. Or pick *Internal Microphone* in Settings → Sound while jack headphones are plugged in |
| Wi-Fi | Broadcom BCM4350 `14e4:43a3` | brcmfmac | ✅ | Works on brcmfmac. Board-specific NVRAM/CLM files are missing (normal). A leftover `broadcom-sta` (wl) crashed every boot and was removed with [macbook-wifi](../plugins/macbook-linux/skills/macbook-wifi) |
| Bluetooth | Broadcom BCM4350C0 over UART (ACPI `BCM2E7C`) | hci_uart_bcm (patched, DKMS) | 🔧 | Stock driver failed ~1 in 3 boots (`0xfc18 tx timeout`). Fixed with the patched driver from [macbook-bluetooth](../plugins/macbook-linux/skills/macbook-bluetooth) plus removing broadcom-sta (wl) with [macbook-wifi](../plugins/macbook-linux/skills/macbook-wifi): 5 of 5 clean boots since. For Bluetooth audio, use 5 GHz Wi-Fi |
| Webcam | FaceTime HD `14e4:1570` | facetimehd (DKMS) | 🔧 | Works with the out-of-tree driver and extracted firmware: 1296×736 at 30 fps, via [facetimehd-webcam](../plugins/macbook-linux/skills/facetimehd-webcam) |
| Thunderbolt 3 / USB-C | Intel Alpine Ridge JHL6540 | thunderbolt, xhci_hcd | ⚠️ | Charging always works. USB-C **data** stops after the first sleep until reboot, because Apple firmware powers the controller off. A PCI rescan does not bring it back. Unsolved |
| Fans / sensors (SMC) | Apple SMC | applesmc | ⚠️ | Readable. No fan daemon by default (`mbpfan` optional) |
| Ambient light sensor | via applesmc | applesmc | ⚠️ | Readable, not wired into auto-brightness |
| Battery | bq20z451 | ACPI | ✅ | Health and cycle count readable |
| Suspend / resume | | | 🔧 | **s2idle only**; deep S3 never resumes reliably. Needs NVMe and Thunderbolt kept out of D3cold, and wake sources limited to the lid and EC. To wake, open the lid, then press the power button. [macbook-sleep](../plugins/macbook-linux/skills/macbook-sleep) |

## Known issues and fixes

### Suspend (verified 2026-10-18)
Applied with the [macbook-sleep](../plugins/macbook-linux/skills/macbook-sleep) skill, in order; see its notes for this model.
- `mem_sleep_default=s2idle` on the kernel command line
- udev rules keeping the NVMe and the Thunderbolt bridges out of D3cold
- a boot-time service that leaves only `LID0` and `EC` enabled in `/proc/acpi/wakeup` (XHC1/2, RP01/05/09/10, ARPT and SPIT disabled)
- a `system-sleep` hook that reloads `applespi` after resume and re-applies the wake settings

### Bluetooth (verified 2026-10-18)
Two changes together: the patched `hci_uart` (Apple BTLP wake call removed) through DKMS, and removing broadcom-sta (wl). After both: 5 of 5 clean boots, including warm restarts. Five boots can't tell which change mattered more: the patch alone gave 1 failure, in a boot where wl crashed. Before: about 1 in 3 boots failed, more often after warm reboots. Audio tips ("Connect" button = disconnected, `Stream End Point in Use` → reconnect, 2.4 GHz coexistence) are in the skill's `references/audio.md`.

### Webcam (verified 2026-10-18)
`facetimehd` 0.7.2 via DKMS. Firmware 5.60.0 extracted from Apple's macOS 10.12.6 update into `/usr/lib/firmware/facetimehd/`. Shows up as `/dev/video0` and in PipeWire.

### Trackpad (verified 2026-10-18)
With the [mac-trackpad](../plugins/macbook-linux/skills/mac-trackpad) skill: `tap-to-click false`, `click-method fingers`. Two-finger scrolling was far too fast, and GNOME has no setting for it, so the trackpad resolution is doubled through hwdb (96/94 → 192/188). The pointer speed was then raised to compensate, ending on adaptive at speed 0.4. The macOS cursor theme is apple_cursor v2.0.1.

### Keyboard shortcuts (verified 2026-10-18)
keyd 2.5 with the [mac-keyboard-shortcuts](../plugins/macbook-linux/skills/mac-keyboard-shortcuts) skill. On Ubuntu the binary is `keyd.rvaiya`.

## Kernel log notes
- `ACPI ... _OSC/_PDC AE_ALREADY_EXISTS`, `\_SB.OSCP AE_NOT_FOUND`: Apple firmware quirks, harmless
- `thunderbolt: device links to tunneled native ports are missing!`: informational
- `snd_hda_intel: Primary patch_cs8409 NOT FOUND trying APPLE`: no model-specific profile, generic Apple setup (headset mic unsupported). Community driver [davidjo/snd_hda_macbookpro](https://github.com/davidjo/snd_hda_macbookpro) exists, but its own README says headset/internal mic input is incomplete
- `nvme0n2` partition table warning: Apple's 8K namespace, harmless
- brcmfmac `Direct firmware load ... MacBookPro13,1.txt failed`: missing board NVRAM, see Wi-Fi (harmless)
- `Bluetooth: hci0: unknown advertising packet type`: printed while scanning, harmless
