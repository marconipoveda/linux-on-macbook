---
name: macbook-sleep
description: Diagnose and fix suspend/resume on Linux on Intel Macs. Covers a Mac that never wakes up after closing the lid (black screen, has to be force-rebooted), wakes itself seconds after suspending, takes a minute to resume, wakes repeatedly in a bag, drains battery while asleep, or comes back with a broken trackpad or dead USB-C ports. Uses udev D3cold rules, ACPI wake-source control, s2idle vs deep sleep, resume hooks, and hibernation with suspend-then-hibernate (swap file resume offset, Ubuntu polkit unblock, drivers that break hibernation), applied one at a time and tested. Use this whenever someone on Linux on a MacBook mentions suspend, sleep, lid close, resume, hibernate, suspend-then-hibernate, "hibernate is greyed out / not allowed", "won't wake up", a warm Mac in the bag, or battery dying overnight.
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
- **A wake that always takes 10–20 s, whatever wakes it** (lid, power button, RTC alarm), with Linux's own resume under 2 s, is the firmware. Measure it before chasing drivers: set an RTC alarm with `rtcwake -m no`, turn on `/sys/power/pm_print_times`, suspend with the lid open and time the screen against the alarm. On MacBookPro11,4 (aftermarket NVMe) it's ~15 s and shows up as a 14–18 s jump in kernel timestamps right after `Filesystems sync`. Linux can't shorten it; s2idle skips it at the cost of much higher drain.
- **Don't install TLP, auto-cpufreq, laptop-mode-tools or `powertop --auto-tune` as a sleep fix.** They change dozens of settings at once and make it impossible to tell what helped.

## 3. Battery while asleep, and hibernation

s2idle uses more power than S3: on MacBookPro13,1 about 5 W, enough to empty the battery overnight and make the Mac warm in a bag. To measure it, run `bash scripts/sleep-drain.sh start` on battery before closing the lid, and `bash scripts/sleep-drain.sh stop` after waking. Under about 1.5 %/h is fine. More than that is the case for **suspend-then-hibernate**: on battery the lid sleeps as usual, and after a delay the Mac wakes by itself, saves memory to swap and powers off. On the charger it only sleeps.

Discuss it with the person first. After hibernation, the Mac takes about 30 s to come back (power button, firmware, restore) instead of an instant wake. The delay decides how often that happens: the person on 13,1 picked 10 minutes.

Use `scripts/hibernate.sh`, one step at a time, in this order:

1. **`--status`**: shows lockdown, swap, RAM, resume settings and what logind allows. Kernel lockdown (Secure Boot) forbids hibernation outright; say so and stop.
2. **`--setup`**, then reboot. It grows a swap file to more than RAM (or warns if a partition is too small) and works out `resume=` and `resume_offset=`. It adds them through `/etc/default/grub.d` and makes the initramfs (dracut or initramfs-tools) include resume support. After the reboot, `--status` must show a resume device other than `0:0`. `PM: Image not found (code -22)` on a normal boot is expected: it only means there was nothing to restore.
3. **`--allow`**, on Ubuntu. Ubuntu forbids hibernation in polkit (`com.ubuntu.desktop.rules`), so logind reports `CanHibernate` as `no` even when everything else is ready. The override in `/etc/polkit-1/rules.d` applies at once. `na` instead of `no` means a kernel or swap problem, not policy.
4. **`--test`**: writes the image and restores it straight away, with no power-off and kernel logs kept. Use this instead of `systemctl hibernate` for the first try. A real hibernation that fails loses every log line, and the person just sees the Mac turn off and later start fresh. Read the output:
   - `Hibernation image restored successfully`: go on.
   - `quiesce of devices aborted` / `freeze of devices aborted` with a driver name just above it: that driver breaks hibernation. On 13,1 it was **brcmfmac** (`brcmf_pcie_pm_enter_D3: Timeout`). That left Wi-Fi dead and the desktop hanging until a forced restart. Fix with `--unload "brcmfmac_wcc brcmfmac"` (the hook unloads it before hibernating and reloads it after), then `--test` again.
   - No "Writing hibernation image" or "Image saving" lines at all: the image was never written. Check `--status` again.
   - If the Mac hangs during the test, it's the same driver problem: hold the power button and look at the previous boot's journal (`journalctl -b -1 -k`). `--test` turns on `pm_debug_messages`, so the failing step shows up there.
5. **A real `systemctl hibernate`**: the Mac should power off by itself and, after the power button, come back to the lock screen with the windows still open.
6. **Check that the RTC can wake the Mac from sleep.** suspend-then-hibernate depends on it. Test it the way the lid would: `sudo rtcwake -m no -s 90 && systemctl suspend`. It should wake by itself after about 90 s. Don't use `rtcwake -m freeze`: it skips the desktop, so the screen stays on with the last picture. If keyboard wake is disabled (SPIT), that looks exactly like a frozen machine. Opening the lid wakes it.
7. **`--lid 2min`**, then reboot, so logind reads the lid setting. Unplug the charger, close the lid for 4 minutes and open it. The screen should stay dark until the power button is pressed. Then set the real delay with `--lid 10min` (or whatever the person picks); delay changes need no reboot.
8. **`--grub-no-wait`**, on Ubuntu GRUB. A hibernation leaves `recordfail` set, and the next start would wait 30 s on a hidden boot menu. This sets `GRUB_RECORDFAIL_TIMEOUT=0`; Esc during start-up still opens the menu.

Explain the delay plainly: it's how long the Mac stays in instant-wake sleep after the lid closes. It's not how long it takes to come back. People mix the two up.

## 4. Known unsolved

On 2016–2017 MacBook Pros, **USB-C data (Thunderbolt xHCI) dies after the first sleep** until a reboot; charging still works. Apple firmware powers the controller off and doesn't bring it back, and a PCI remove/rescan doesn't revive it. Say this up front, so the person doesn't chase it. If you find a working fix, add it here.

## Undo

`sudo bash scripts/uninstall.sh`, then reboot. It removes the rules, the service, the hooks, the config, the hibernation settings (polkit rule, lid and sleep config, resume parameters) and the GRUB snippets. It leaves the swap file alone.
