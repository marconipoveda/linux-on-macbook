---
name: macbook-hardware-scan
description: Scan an Intel Mac running Linux (MacBook Pro, MacBook Air, MacBook, iMac, Mac mini) and produce a hardware status page showing what works, what's partial, what's broken, and which fix applies to each problem, then plan the work. Use this whenever someone has just installed Ubuntu or another distro on a Mac and asks what works or what needs fixing, wants to "check the hardware", "scan this Mac", "see what drivers are missing", or wants to add a new Mac model to the linux-on-macbook repo. It is also the right first step before fixing the webcam, Wi-Fi, Bluetooth, audio or sleep on a Mac when no model page exists yet.
---

# MacBook hardware scan

This skill is how a new Mac gets added to the linux-on-macbook project. The goal is a **model page**: one table of every component with its status and the fix to use. It tells the person what to work on next, and once shared, it saves the next owner of that model the same investigation.

## 1. Run the scan

```bash
bash scripts/scan.sh > scan-$(cat /sys/class/dmi/id/product_name | tr -d ' ').txt
```

The scan is read-only and needs no root. It masks MAC addresses and the hostname so the output can be shared publicly. It only keeps all-zero addresses, because a Bluetooth controller showing `00:00:00:00:00:00` is itself a symptom. It covers DMI identity, PCI/USB devices with their bound drivers, input devices, DKMS modules, backlight, network, Bluetooth, webcam, audio, battery health, sleep states and wake sources, SMC fans and sensors, power services, packages of note, and kernel log errors.

Read the whole output. The useful signal is often in the kernel log section: `Direct firmware load ... failed`, a driver that bound and then failed, or a WARNING/Call Trace.

## 2. Check what's already known

- Look for `models/<ProductName>.md` in the repo (two levels up from the plugin, or on GitHub). If it exists, compare against it and update it rather than starting over.
- List the other skills in this plugin (`../`). Each skill fixes one component on any model, and keeps per-model quirks in `references/models/<ProductName>.md`. Map each problem you find to a skill when one fits.

## 3. Judge each component

Fill in `assets/model-template.md`. These judgment calls come up on almost every Mac:

- **Bound driver ≠ working.** `lspci -k` shows the driver loaded, but the status depends on the symptom. Bluetooth with address `00:00:00:00:00:00` or "No default controller" is ❌, even though `hci_uart` loaded.
- **Competing Wi-Fi drivers.** `broadcom-sta`/`wl` installed alongside `brcmfmac` means the two fight over the card. Note which one actually owns the device, and flag the other for removal.
- **Missing firmware ≠ broken.** brcmfmac often works without the board-specific `.txt`/`clm_blob`, just with reduced channels or power. That's ⚠️, not ❌.
- **Webcam:** Macs from roughly 2013–2017 have the Broadcom `14e4:1570` FaceTime HD camera. It's never ✅ out of the box: it needs the out-of-tree `facetimehd` driver plus firmware extracted from Apple's driver package.
- **Keyboard and trackpad generation:** USB (`hid_apple`, `bcm5974`; up to 2015), SPI (`applespi`; 2016–2017), or T2 (`apple-bce`; 2018 and later). This decides which fixes apply.
- **Sleep:** you can't judge it from the scan. Mark it ❔ unless the person has tested it. Record `mem_sleep` (s2idle vs deep) and the wake sources, since those drive the fix.
- **Battery:** report health as full/design capacity, plus the cycle count.
- **Things the scan can't see** (speakers, mic, headphone jack, SD reader, brightness keys): mark them ❔ and ask the person to test.

## 4. Write the page and a work order

Save the page as `models/<ProductName>.md`, using the exact DMI product name, e.g. `MacBookPro11,4.md`. Below the table, add a short prioritized work order. Put things that block daily use first (Wi-Fi, sleep, keyboard), quick wins next, and cosmetic tuning last. For each item, name the skill that fixes it, or say that there is none yet.

Show the person the table and the work order before starting any fixes.

## 5. Contributing back

If the person is working in the linux-on-macbook repo:

- add a column for the model to the status matrix in the top-level `README.md`
- when a fix is verified on this model, add `references/models/<ProductName>.md` inside that fix's skill
- leave out serial numbers, MAC addresses, hostnames, usernames and home-directory paths. The scan already strips the first three.
