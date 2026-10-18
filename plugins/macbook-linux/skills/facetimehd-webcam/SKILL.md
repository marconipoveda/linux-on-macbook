---
name: facetimehd-webcam
description: Get the built-in FaceTime HD webcam working on Linux on Intel MacBooks, iMacs and Mac minis from about 2013–2017 (Broadcom PCIe camera 14e4:1570). It installs the out-of-tree facetimehd driver through DKMS and extracts the camera firmware from Apple's update package. Use this whenever someone on Linux on a Mac says the webcam or camera doesn't work, "no camera found", there's no /dev/video0, Zoom/Meet/Firefox can't see the camera, or they mention facetimehd, even if they don't know the camera model.
---

# FaceTime HD webcam on Linux

Most Intel Macs from about 2013 to 2017 have a Broadcom FaceTime HD camera (PCI ID `14e4:1570`). The kernel has no driver for it. The community driver [facetimehd](https://github.com/patjak/facetimehd) works well, but it needs firmware that only ships inside Apple's macOS update. That firmware can't be redistributed, so each machine extracts its own copy with the [facetimehd-firmware](https://github.com/patjak/facetimehd-firmware) scripts.

## 1. Check the hardware

Run `bash scripts/check.sh` (read-only). It tells you:

- **Whether the camera is a `14e4:1570` at all.** Older Macs have a USB iSight, which works with `uvcvideo` out of the box. T2 Macs (2018 and later) route the camera through `apple-bce`. If there's no `14e4:1570`, this skill doesn't apply: say so and stop.
- **Whether facetimehd is already installed or partly installed:** a DKMS entry, firmware files, a loaded module.
- **Whether the kernel ships its own driver.** A mainline driver was being reviewed in 2026. If `modules.alias` lists a module other than `facetimehd` for this device, use that instead; installing facetimehd as well would make two drivers fight over the camera. The firmware is still needed.
- **What's missing to build it:** kernel headers, dkms, gcc, git, curl, xz, cpio. On Ubuntu/Debian, `cpio` and `xz-utils` are sometimes missing.

If `references/models/<product_name>.md` exists, read it.

## 2. Download and extract (normal user)

```bash
bash scripts/fetch.sh            # into ~/facetimehd-build
```

The script:
- downloads about 18 MB of byte ranges of Apple's macOS 10.12.6 update straight from `updates.cdn-apple.com`; upstream's script checks the hash of each extracted file
- produces `firmware.bin` plus 11 sensor calibration files (`*_01XX.dat`)
- clones the driver at a known-good tag (`DRV_TAG`, default `0.7.2`; override it for newer kernels)

Don't download firmware from anywhere else. Apple's CDN is the only trustworthy source. If extraction fails with `xzcat: Unexpected end of input`, the download was cut off. The script retries; otherwise check the network or proxy.

## 3. Install (root, the person runs it)

```bash
sudo bash scripts/install.sh     # uses ~/facetimehd-build of the sudo user
```

The script:
- installs build dependencies
- copies the firmware into `/usr/lib/firmware/facetimehd/`
- removes old facetimehd DKMS versions
- registers the driver with DKMS so it rebuilds automatically on kernel updates; it fixes upstream's stale `dkms.conf` along the way (wrong `PACKAGE_VERSION`, and a `MODULES_CONF` line newer DKMS rejects)
- loads the module and ends with `RESULT:`; the log is at `~/facetimehd-build/install.log`

Root steps go in a script the person runs in their own terminal, because sudo can't prompt for a password inside an agent's shell.

## 4. Verify (normal user)

```bash
bash scripts/verify.sh           # writes ~/facetimehd-test.jpg
```

- Expect "Apple Facetime HD" on `/dev/video0` with YUYV formats, and a camera entry in PipeWire's Video section.
- Look at the test JPEG and make sure it's a real picture. The first frames are dark while auto-exposure settles; the script skips 60 frames.
- Then have the person try their browser or video-call app.

**If `/dev/video0` doesn't appear,** ask for one reboot before troubleshooting; upstream notes the first load sometimes needs it. Then check `journalctl -k | grep -i facetimehd`:
- `Loaded firmware` and `Enabling interrupts`: the driver is fine; look at app permissions or the `video` group
- firmware load errors: re-run fetch.sh
- `Failed to lock S2 PLL` followed by `locked on safe settings`: normal

**DKMS build errors** after a kernel update usually mean the driver tag is too old for that kernel. Check the [upstream tags](https://github.com/patjak/facetimehd/tags), then re-run fetch.sh with `DRV_TAG=<new>` and install.sh.

**Secure Boot:** Intel Macs without T2 don't enforce it. If `mokutil --sb-state` says enabled, DKMS signs the module with a MOK key that has to be enrolled at the next boot. Walk the person through that prompt.

## 5. Suspend and resume

The driver refuses to suspend while an app has the camera open, so close camera apps before closing the lid. Ask the person to test once: suspend, resume, then run verify.sh again. **Only if the camera breaks after resume,** install `assets/99facetimehd` to `/usr/lib/systemd/system-sleep/` (mode 755). It unloads the module before sleep and reloads it after.

## Undo

`sudo bash scripts/uninstall.sh` removes the DKMS module, the firmware and the sleep hook. Add `--keep-firmware` when switching to an in-tree driver, which still needs the firmware.
