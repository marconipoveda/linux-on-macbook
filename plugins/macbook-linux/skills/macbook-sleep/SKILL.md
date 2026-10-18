---
name: macbook-sleep
description: Diagnose and fix suspend/resume on Linux on Intel Macs. Covers a Mac that never wakes up after closing the lid (black screen, has to be force-rebooted), wakes itself seconds after suspending, takes a minute to resume, wakes repeatedly in a bag, drains battery while asleep, or comes back with a broken trackpad or dead USB-C ports. Uses udev D3cold rules, ACPI wake-source control, s2idle vs deep sleep, and resume hooks, applied one at a time and tested. Use this whenever someone on Linux on a MacBook mentions suspend, sleep, lid close, resume, hibernate, "won't wake up", or battery dying overnight.
---

# Suspend and resume on Intel Macs

Mac firmware does several things Linux doesn't expect: Apple NVMe SSDs that never return from D3cold, Thunderbolt controllers that take a minute to power back up, and ACPI wake sources that fire immediately. Each has a small fix. The skill of it is figuring out *which* problems this Mac has, and applying fixes **one at a time with a test in between**, so nothing unnecessary gets installed.

## Safety first

A failed resume means a forced power-off. Before **every** suspend test, tell the person to save their work and close everything except a terminal. If the Mac doesn't wake within about a minute, hold the power button for 10 seconds and boot normally. Nothing here persists in a way that prevents booting.

Root steps go through `scripts/install.sh`, which the person runs in their own terminal. sudo can't prompt for a password inside an agent's shell.

## 1. Diagnose (read-only)

`bash scripts/diagnose.sh` reports:
- the model and the current sleep mode (`s2idle` or `deep`)
- the enabled ACPI wake sources
- NVMe and Thunderbolt devices with their `d3cold_allowed` state
- the keyboard/trackpad driver
- sleep hooks and rules already installed
- **whether recent boots ended on `PM: suspend entry`**: a boot that ends there means the Mac never resumed
- recent wake events and slow-resume errors

Read `references/models/<product_name>.md` if it exists. It gives the verified fix set for that model, and you can skip straight to applying it, still one fix at a time. Otherwise, match the symptoms with `references/diagnosis.md`.

Ask the person what they actually see:
- never wakes
- wakes right away
- slow wake
- trackpad broken after wake
- battery drain while asleep

Their answer, plus the diagnosis, decides the order.

## 2. Fix, one at a time

| Symptom | Likely cause | Fix |
|---|---|---|
| Never resumes; journal ends at `suspend entry` (2016–2017 MBP) | Apple NVMe doesn't come back from D3cold | `sudo bash install.sh --nvme` (applies now, no reboot needed) |
| Resume takes 60 s or more; `Unable to change power state from D3cold` on TB bridges | Thunderbolt chain powered off | `--thunderbolt`, then reboot |
| Wakes 1–3 s after suspending | USB/PCIe/Wi-Fi wake sources | `--wake "XHC1 XHC2 RP01 RP05 RP09 RP10 ARPT"`, using the names actually enabled on this Mac |
| Wakes every ~30 s with the lid closed (SPI models) | the closed lid presses the keyboard/trackpad (`SPIT`) | add `SPIT` to `--wake`, and `--keep "LID0 EC"` |
| Still never resumes from deep, even with the above | firmware S3 bug on that model | `--s2idle`, then reboot |
| Trackpad garbled after resume (`applespi: Received corrupted packet`) | SPI trackpad state lost | `--applespi-hook` |

After each fix, test with an actual suspend: close the lid for at least 2 minutes (some failures only show after a minute or so), then open it and press a key or the power button. Run `diagnose.sh` again and look at the new PM lines. Ask the person how it went, then pick the next fix.

Notes on the fixes:
- **Wake sources** live in `/etc/macbook-sleep/wakeup.conf`. They're applied at boot by `macbook-wakeup.service` and again after every resume by the sleep hook, because reloading drivers re-enables their own wake flags. Writing a name to `/proc/acpi/wakeup` *toggles* it, which is why the helper checks the state first. Never echo names there by hand in a loop.
- **On s2idle, opening the lid alone may not wake the Mac.** On MacBookPro13,1 you have to open the lid *and* press the power button. Tell the person rather than promising lid wake.
- **Don't install TLP, auto-cpufreq, laptop-mode-tools or `powertop --auto-tune` as a sleep fix.** They change dozens of settings at once and make it impossible to tell what helped.

## 3. Battery while asleep (optional)

s2idle uses more power than S3. To measure it, run `bash scripts/sleep-drain.sh start` on battery before closing the lid, and `bash scripts/sleep-drain.sh stop` after waking, after a few hours or overnight. Under about 1.5 %/h is fine. Much more than that is a reason to look at `HandleLidSwitch=suspend-then-hibernate`, which needs a swap area at least as big as RAM and a `resume=` kernel parameter. That's a separate project: discuss it with the person first.

## 4. Known unsolved

On 2016–2017 MacBook Pros, **USB-C data (Thunderbolt xHCI) dies after the first sleep** until a reboot; charging still works. Apple firmware powers the controller off and doesn't bring it back, and a PCI remove/rescan doesn't revive it. Say this up front, so the person doesn't chase it. If you find a working fix, add it here.

## Undo

`sudo bash scripts/uninstall.sh`, then reboot. It removes the rules, the service, the hook, the config and the GRUB snippet.
