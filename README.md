# linux-on-macbook

Make Linux run well on Intel MacBooks. Each fix here was worked out and verified on a real machine.
Every fix is a **Claude skill** (Claude can apply it for you) and also a set of plain scripts you can
run yourself.

## Status by model

✅ works out of the box · 🔧 works after a fix here · ⚠️ partial · ❌ not working · ❔ not tested yet

| Component | [MacBookPro13,1](models/MacBookPro13,1.md)<br>13" 2016 | [MacBookPro11,4](models/MacBookPro11,4.md)<br>15" Mid 2015 |
|---|---|---|
| Mac-style keyboard shortcuts | 🔧 [keyd](plugins/macbook-linux/skills/mac-keyboard-shortcuts) | 🔧 [keyd](plugins/macbook-linux/skills/mac-keyboard-shortcuts) |
| Trackpad: clicking, pointer and scroll speed | 🔧 [settings + scroll fix](plugins/macbook-linux/skills/mac-trackpad) | 🔧 [clicking only](plugins/macbook-linux/skills/mac-trackpad); speeds fine by default |
| macOS cursor | 🔧 [apple_cursor](plugins/macbook-linux/skills/mac-trackpad) | ❔ |
| Webcam (FaceTime HD) | 🔧 [facetimehd](plugins/macbook-linux/skills/facetimehd-webcam) | 🔧 [facetimehd](plugins/macbook-linux/skills/facetimehd-webcam) |
| Suspend / resume | 🔧 [s2idle + fixes](plugins/macbook-linux/skills/macbook-sleep) | ✅ deep sleep, no fixes; wake takes ~15 s (firmware) |
| Hibernation (sleep, then hibernate on battery) | 🔧 [Wi-Fi unloaded + polkit unblock](plugins/macbook-linux/skills/macbook-sleep) | not needed: 0.1 %/h asleep |
| Wi-Fi | ✅ brcmfmac ([remove wl](plugins/macbook-linux/skills/macbook-wifi)) | ✅ brcmfmac |
| Bluetooth | 🔧 [patched driver + wl removed](plugins/macbook-linux/skills/macbook-bluetooth) | ✅ USB (btusb), no patch needed |
| Audio: speakers, internal mic, headphones | ✅ | ✅ speakers + internal mic; headphones ❔ |
| Audio: headset mic (jack) | ❌ driver limitation, use a USB headset (✅) | ❔ |
| USB-C data after sleep | ❌ | n/a |

Each model page has the full component table, the hardware IDs, and the kernel log notes.

## Skills

| Skill | What it does |
|---|---|
| [macbook-hardware-scan](plugins/macbook-linux/skills/macbook-hardware-scan) | Scans a Mac and writes its model page: what works, what doesn't, which fix to use |
| [macbook-bluetooth](plugins/macbook-linux/skills/macbook-bluetooth) | BCM UART Bluetooth that fails at boot (patched hci_uart via DKMS, boot checker), plus speaker/headphone troubleshooting |
| [macbook-wifi](plugins/macbook-linux/skills/macbook-wifi) | Broadcom Wi-Fi: brcmfmac vs wl, removing a crashing broadcom-sta, firmware messages |
| [macbook-sleep](plugins/macbook-linux/skills/macbook-sleep) | Suspend/resume: NVMe and Thunderbolt D3cold, wake sources, s2idle, resume hooks, hibernation and suspend-then-hibernate, one fix at a time |
| [mac-keyboard-shortcuts](plugins/macbook-linux/skills/mac-keyboard-shortcuts) | Cmd+C/V, Cmd+Tab, Cmd+Space, Option+arrows… on any distro and desktop, using keyd |
| [facetimehd-webcam](plugins/macbook-linux/skills/facetimehd-webcam) | FaceTime HD camera (2013–2017 Macs): facetimehd driver via DKMS + firmware from Apple's update |
| [mac-trackpad](plugins/macbook-linux/skills/mac-trackpad) | No accidental tap-clicks, two-finger right-click, pointer speed, slower two-finger scrolling (GNOME has no setting), browser glide, macOS cursor |


## Install (Claude Code)

```
/plugin marketplace add marconipoveda/linux-on-macbook
/plugin install macbook-linux@linux-on-macbook
```

Then just ask, for example: *"scan this Mac"*, or *"make my keyboard work like macOS"*.

## Use without Claude

Every skill folder has a `SKILL.md` that reads as a step-by-step guide, plus `scripts/` you can run directly.
Example, keyboard:

```bash
cd plugins/macbook-linux/skills/mac-keyboard-shortcuts
bash scripts/detect.sh
bash scripts/make-config.sh gnome > mac-keys.conf        # or kde | other
sudo bash scripts/install.sh "$PWD/mac-keys.conf"
bash scripts/gnome-shortcuts.sh                          # GNOME only
```

## Adding your Mac

1. Run `bash plugins/macbook-linux/skills/macbook-hardware-scan/scripts/scan.sh > scan.txt`. It's read-only, and MAC addresses and the hostname are masked.
2. Create `models/<ProductName>.md` from `plugins/macbook-linux/skills/macbook-hardware-scan/assets/model-template.md`. Or let Claude do steps 1–2 with the scan skill.
3. Add a column to the table above and open a pull request.

When a fix works on your model, add a short `references/models/<ProductName>.md` in that skill with whatever was different.

## Layout

```
models/                     one page per Mac model (status + notes)
plugins/macbook-linux/      Claude Code plugin
  skills/<component>/       one skill per problem; works across models
    references/models/      per-model quirks for that fix
.claude-plugin/             marketplace manifest
```

## License

MIT. Third-party drivers (keyd, facetimehd) and Apple firmware are not included. The skills download them from their original sources.
