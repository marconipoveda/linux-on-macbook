# MacBookPro13,1 (13" 2016): verified fix set (2026-10-18, Ubuntu 26.04, kernel 7.0)

Apply in this order, testing a suspend after each:

1. `--nvme`: without it resume never works (journal ends at `suspend entry`). Necessary, but on its own it didn't make deep sleep reliable.
2. `--thunderbolt`: the TB bridges took 60–85 s to resume (pm_test `platform` stage 85 s). With the rule: about 10 s.
3. `--wake "XHC1 XHC2 RP01 RP05 RP09 RP10 ARPT SPIT" --keep "LID0 EC"`: without it the Mac woke about 2 s after suspending; with only USB/PCIe off, SPIT woke it every ~34 s with the lid closed.
4. `--s2idle`: deep S3 after ~2 min asleep never resumed (the firmware rebooted). s2idle resumes reliably.
5. `--applespi-hook`: the trackpad was sometimes garbled after s2idle resume.

Result: closing the lid suspends (s2idle). **To wake: open the lid, then press the power button.** Lid-open alone doesn't wake it, even with EC enabled.

## Hibernation and suspend-then-hibernate (verified 2026-10-19)

Why: s2idle draws about 5 W here. A night with the lid closed emptied the battery, and the Mac got warm. Steps with `hibernate.sh`, in order:

1. `--setup`: Ubuntu's `/swap.img` (4 GiB) grown to 8 GiB for 7.1 GiB RAM; `resume=UUID=<root> resume_offset=<filefrag first extent>`; dracut `resume` module (Ubuntu 26.04 builds the initramfs with dracut).
2. `--allow`: before it, logind reported `CanHibernate` as `no` (Ubuntu's polkit rule).
3. `--unload "brcmfmac_wcc brcmfmac"`: **needed.** Without it, `--test` saved and read back the image fine, but the restore aborted: `brcmf_pcie_pm_enter_D3: Timeout on response for entering D3 substate` → `quiesce of devices aborted` → `Failed to load image, recovering`. Wi-Fi was then dead (`Failed to reserve space in commonring`) and GNOME hung until a forced restart. The first real `systemctl hibernate` also powered off without restoring. With the unload: `Hibernation image restored successfully`, and Wi-Fi reconnects by itself.
4. RTC wake from s2idle works: `rtcwake -m no -s 90 && systemctl suspend` woke after 93 s. (`rtcwake -m freeze` left the screen on with the last picture, and since SPIT wake is off, it looked frozen; lid-open woke it.)
5. `--lid 10min`: tested at 2min: lid closed 21:10:55, woke and hibernated after the delay, restored with windows open. Image ~1 GB written in about 1 s (lzo), restore about 35 s from power button to lock screen, mostly firmware.
6. `--grub-no-wait`.

Open: after every resume, the `applespi` reload in the sleep hook fails with `could not remove 'applespi': Device or resource busy`. The trackpad was fine regardless, but the reload isn't actually happening.

Open: USB-C data dies after the first sleep (xHCI 07:00.0 removed, bridges `D3cold to D0, device inaccessible`). Charging is fine. A PCI remove/rescan doesn't revive it.
