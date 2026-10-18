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
| Trackpad | Apple SPI Force Touch | applespi | 🔧 | Mac-style clicking via [mac-trackpad](../plugins/macbook-linux/skills/mac-trackpad) (tap-to-click off, two-finger right-click). No haptics. Can come back garbled after resume until `applespi` is reloaded (fixed by the sleep hook) |
| Keyboard backlight | `spi::kbd_backlight` | applespi | ✅ | |
| Audio (speakers / mic / jack) | Cirrus Logic CS8409 / CS42L83 | snd_hda_codec_cs8409 | ❔ | Codec detected and PipeWire sink present. Upstream support for this model has been incomplete |
| Wi-Fi | Broadcom BCM4350 `14e4:43a3` | brcmfmac | ⚠️ | Connects. Board-specific NVRAM/CLM files are missing. If `broadcom-sta` (wl) is installed, remove it: it fails to load and taints the kernel |
| Bluetooth | Broadcom BCM43xx over UART (ACPI `BCM2E7C`) | hci_uart_bcm | ❌ | `hci0` comes up with address `00:00:00:00:00:00`, "No default controller". In progress |
| Webcam | FaceTime HD `14e4:1570` | facetimehd (DKMS) | 🔧 | Works with the out-of-tree driver and extracted firmware: 1296×736 at 30 fps, via [facetimehd-webcam](../plugins/macbook-linux/skills/facetimehd-webcam) |
| Thunderbolt 3 / USB-C | Intel Alpine Ridge JHL6540 | thunderbolt, xhci_hcd | ⚠️ | Charging always works. USB-C **data** stops after the first sleep until reboot, because Apple firmware powers the controller off. A PCI rescan does not bring it back. Unsolved |
| Fans / sensors (SMC) | Apple SMC | applesmc | ⚠️ | Readable. No fan daemon by default (`mbpfan` optional) |
| Ambient light sensor | via applesmc | applesmc | ⚠️ | Readable, not wired into auto-brightness |
| Battery | bq20z451 | ACPI | ✅ | Health and cycle count readable |
| Suspend / resume | | | 🔧 | **s2idle only**; deep S3 never resumes reliably. Needs NVMe and Thunderbolt kept out of D3cold, and wake sources limited to the lid and EC. To wake, open the lid, then press the power button. Skill coming |

## Known issues and fixes

### Suspend (verified 2026-10-18)
- `mem_sleep_default=s2idle` on the kernel command line
- udev rules keeping the NVMe and the Thunderbolt bridges out of D3cold
- a boot-time service that leaves only `LID0` and `EC` enabled in `/proc/acpi/wakeup` (XHC1/2, RP01/05/09/10, ARPT and SPIT disabled)
- a `system-sleep` hook that reloads `applespi` after resume and re-applies the wake settings

### Webcam (verified 2026-10-18)
`facetimehd` 0.7.2 via DKMS. Firmware 5.60.0 extracted from Apple's macOS 10.12.6 update into `/usr/lib/firmware/facetimehd/`. Shows up as `/dev/video0` and in PipeWire.

### Trackpad (verified 2026-10-18)
GNOME: `tap-to-click false` and `click-method fingers`, applied by the [mac-trackpad](../plugins/macbook-linux/skills/mac-trackpad) skill.

### Keyboard shortcuts (verified 2026-10-18)
keyd 2.5 with the [mac-keyboard-shortcuts](../plugins/macbook-linux/skills/mac-keyboard-shortcuts) skill. On Ubuntu the binary is `keyd.rvaiya`.

## Kernel log notes
- `ACPI ... _OSC/_PDC AE_ALREADY_EXISTS`, `\_SB.OSCP AE_NOT_FOUND`: Apple firmware quirks, harmless
- `thunderbolt: device links to tunneled native ports are missing!`: informational
- `nvme0n2` partition table warning: Apple's 8K namespace, harmless
- brcmfmac `Direct firmware load ... MacBookPro13,1.txt failed`: missing board NVRAM, see Wi-Fi
