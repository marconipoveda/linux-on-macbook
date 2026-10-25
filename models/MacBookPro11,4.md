# MacBookPro11,4 — MacBook Pro 15" Mid 2015 (integrated graphics only)

Last scanned: 2026-10-24 · Distro: Ubuntu 26.04.1 LTS · Kernel: 7.0.0-38-generic · Desktop: GNOME 50 (Wayland)

## Device status

Legend: ✅ works out of the box · 🔧 works after a fix (linked) · ⚠️ partial · ❌ not working · ❔ untested

| Component | Hardware (PCI/USB/ACPI ID) | Driver | Status | Notes / fix |
|---|---|---|---|---|
| CPU | Intel Core i7-4770HQ (Crystal Well / Haswell) | intel_cpufreq (schedutil) | ✅ | thermald and power-profiles-daemon active |
| GPU | Intel Iris Pro 5200 `8086:0d26` | i915 | ✅ | No discrete GPU on 11,4 (11,5 has the AMD one). `apple_gmux` loads but has nothing to switch |
| Display / backlight | 2880×1800 eDP | i915, acpi_video | ✅ | Backlight through `acpi_video0` (0–100). Brightness keys verified 2026-10-25 |
| Storage | Samsung 970 EVO 1 TB NVMe `144d:a808` (aftermarket, via adapter) | nvme | ✅ | Not Apple's original SSD. Watch it during sleep tests: third-party NVMe in these Macs can be a sleep/resume issue |
| Keyboard | Apple Internal Keyboard `05ac:0274` (USB) | hid_apple | ✅ | USB generation (pre-2016). Mac-style shortcuts: 🔧 [mac-keyboard-shortcuts](../plugins/macbook-linux/skills/mac-keyboard-shortcuts) |
| Trackpad | Force Touch trackpad `05ac:0274` (USB) | bcm5974 | 🔧 | Mac-style clicking via [mac-trackpad](../plugins/macbook-linux/skills/mac-trackpad): tap-to-click off, `click-method fingers`. Pointer and scroll speed fine at GNOME defaults (speed 0, natural scroll), no hwdb scroll fix needed, unlike 13,1. No haptics. Display at 125 % scale |
| Keyboard backlight | `smc::kbd_backlight` | applesmc | ✅ | Verified 2026-10-25: lights on, and the keyboard-brightness keys raise and lower it |
| Audio (speakers / mic / jack) | Cirrus Logic CS4208 `8086:8c20` | snd_hda_codec_cs420x | ✅ | Verified 2026-10-25 via PipeWire: both speakers with correct left/right (`speaker-test -c 2 -t wav`), internal mic clear at about −20 to −30 dBFS speaking normally. Headphone jack: plug-in detected (`Headphone Jack` on), output switches to Headphones automatically, correct left/right, speakers muted. Headset mic (jack) not tested |
| Wi-Fi | Broadcom BCM43602 `14e4:43ba` | brcmfmac | ✅ | No broadcom-sta/wl installed. Board-specific `.bin`/`.txt`/`clm_blob`/`txcap_blob` missing (normal); verified 5 GHz, 80 MHz, 540/1300 Mbit/s. [macbook-wifi](../plugins/macbook-linux/skills/macbook-wifi) |
| Bluetooth | Broadcom `05ac:8290` over **USB** | btusb + btbcm | ✅ | 9 of 10 logged boots OK. The one failure (warm reboot) was `hci0: command 0x0c03 tx timeout` / `BCM: Reset failed (-110)`, not the UART `0xfc18` bug. The skill's patched `hci_uart` does **not** apply to this model |
| Webcam | FaceTime HD `14e4:1570` | facetimehd (DKMS) | 🔧 | Works with the out-of-tree driver and extracted firmware, no reboot needed: `/dev/video0`, shows in PipeWire, 1280×720 test frame. Via [facetimehd-webcam](../plugins/macbook-linux/skills/facetimehd-webcam). Not yet tested across suspend |
| HDMI | HDMI port, connector HDMI-A-3 on Iris Pro | i915 | ✅ | Verified 2026-10-25 with a Dell U2412M: 1920×1200, sharp picture, extended desktop with windows moving between screens. While plugging in, i915 logged `HPD interrupt storm detected on connector HDMI-A-3: switching from hotplug detection to polling`, so detection took a few seconds; harmless |
| Thunderbolt 2 / USB-A | Intel Falcon Ridge DSL5520 `8086:156d`/`156c` | thunderbolt, xhci_hcd | ❔ | Bridge-window "failed to assign" messages at boot (no device attached). Thunderbolt/Mini DisplayPort hotplug not tested |
| SD card reader | Apple `05ac:8406` (USB) | usb-storage | ❔ | Shows up as `sda` (0 B, no card). Insert a card to test |
| Fans / sensors (SMC) | Apple SMC | applesmc | ✅ | Both fans readable at ~2000 rpm idle; SMC controls them, `mbpfan` not needed so far |
| Ambient light sensor | via applesmc | applesmc | ⚠️ | Readable, not wired into auto-brightness |
| Battery | | ACPI | ✅ | Health 79 % (6.77 / 8.60 Ah), 241 cycles |
| Suspend / resume | | | ✅ | **Deep (S3) works out of the box**, no fixes needed (unlike 13,1). 3 of 3 logged resumes clean and instant; Wi-Fi, Bluetooth and the facetimehd webcam all come back. **Wake takes ~15 s** (lid, power button or RTC alike), spent in Apple firmware before Linux resumes; Linux's own resume is <2 s. Keys don't wake it. Wake sources enabled: PEG0, PEG1, RP03, RP04, XHC1 (S3); ARPT, LID0 (S4). **Drain asleep: 0.1 %/h (~0.06 W)**, 16.4 h overnight on battery, no spurious wakes |
| Hibernation | 4 GiB swap | | ❔ | Not needed: deep sleep drain is ~1.5 % per night. Not set up (swap smaller than RAM) |

## Known issues and fixes

### Keyboard shortcuts (verified 2026-10-24)
keyd 2.5.0 with the [mac-keyboard-shortcuts](../plugins/macbook-linux/skills/mac-keyboard-shortcuts) skill, GNOME config, Spanish (`es`) layout so right Option stays AltGr. keyd matched the internal keyboard; all shortcuts verified.

### Webcam (verified 2026-10-24)
`facetimehd` 0.7.2 via DKMS on kernel 7.0.0-38. Firmware extracted from Apple's macOS 10.12.6 update into `/usr/lib/firmware/facetimehd/`. The camera came up right after install, no reboot needed, even though install.sh printed "no camera yet": it checked before `/dev/video0` appeared.

### Suspend (verified 2026-10-24)
Stock Ubuntu settings, deep S3. Resumes on 2026-10-10 (~4 h asleep) and 2026-10-24 (1 min, then 6 min with the lid closed, on battery, with facetimehd loaded) were all clean: `Waking up from system sleep state S3` and `PM: suspend exit` in the same second, no D3cold or timeout errors. brcmfmac re-probes the Wi-Fi on resume and reconnects. facetimehd reloads its firmware on resume by itself, so the skill's `99facetimehd` hook isn't needed. **Slow wake (measured 2026-10-24):** an RTC alarm with the lid open brought the screen back ~15 s after the alarm. With `pm_print_times` on, Linux's resume was under 2 s in total: noirq resume 1.08 s (almost all in `pcieport 0000:00:01.0`, the root port of the aftermarket NVMe), device resume 0.52 s (facetimehd 0.52 s, brcmfmac 0.18 s). Every logged suspend since 2026-10-10 shows the same 14–18 s jump in kernel timestamps, so the rest is the firmware's S3 resume path. Suspected, not proven: the firmware re-initializing a non-Apple NVMe (Samsung 970 EVO on an adapter). Boot ROM 489.0.0.0.0 is current. s2idle would skip that path but not tested yet. One boot (2026-10-10) ended on `suspend entry` and the next boot's clock had reset to July: most likely a long sleep that ran the battery flat, not a failed resume.

### Trackpad (verified 2026-10-25)
`gnome-trackpad.sh` from [mac-trackpad](../plugins/macbook-linux/skills/mac-trackpad): tap-to-click off, press-to-click with two-finger right-click. Everything else left at GNOME defaults; the person found it better than the 13,1 out of the box, so the scroll-factor hwdb override wasn't applied.

### Bluetooth is USB on this model
Unlike the 2016–2017 models (UART, `hci_uart_bcm`), the Mid 2015 Bluetooth sits on internal USB and uses `btusb`. The hci_uart DKMS patch doesn't apply. The rare boot failure (1 of 10, after a warm reboot) is a different error (`0x0c03` reset timeout). Untested workaround if it recurs: `sudo modprobe -r btusb && sudo modprobe btusb`, otherwise a full power-off.

## Kernel log notes

- `brcmfmac … Direct firmware load … failed with error -2` for the `MacBookPro11,4.bin`, `.txt`, `.clm_blob`, `.txcap_blob`: harmless, generic firmware is used. Apple's files from `/usr/share/firmware/wifi` on macOS could restore full channels/power.
- `brcmf_inetaddr_changed: fail to get arp ip table err:-52`: harmless, ARP offload not supported by this firmware.
- `pci 0000:06:0x.0: bridge window … failed to assign` and `thunderbolt … device link creation … failed`: Thunderbolt 2 bridges reserved with nothing attached. Only relevant if TB hotplug turns out not to work (`pci=realloc` would be the first thing to try).
- ACPI `FADT/Gpe0Block` length mismatch, `_OSI(Linux) query ignored`, `SystemIO range … conflicts with OpRegion`: standard Apple firmware quirks, harmless.
- `KHO: Failed to reserve lowmem scratch buffer`: kexec handover disabled, harmless.
