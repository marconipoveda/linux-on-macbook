# MacBookPro13,1 (13" 2016): verified fix set (2026-10-18, Ubuntu 26.04, kernel 7.0)

Apply in this order, testing a suspend after each:

1. `--nvme`: without it resume never works (journal ends at `suspend entry`). Necessary, but on its own it didn't make deep sleep reliable.
2. `--thunderbolt`: the TB bridges took 60–85 s to resume (pm_test `platform` stage 85 s). With the rule: about 10 s.
3. `--wake "XHC1 XHC2 RP01 RP05 RP09 RP10 ARPT SPIT" --keep "LID0 EC"`: without it the Mac woke about 2 s after suspending; with only USB/PCIe off, SPIT woke it every ~34 s with the lid closed.
4. `--s2idle`: deep S3 after ~2 min asleep never resumed (the firmware rebooted). s2idle resumes reliably.
5. `--applespi-hook`: the trackpad was sometimes garbled after s2idle resume.

Result: closing the lid suspends (s2idle). **To wake: open the lid, then press the power button.** Lid-open alone doesn't wake it, even with EC enabled.

Open: USB-C data dies after the first sleep (xHCI 07:00.0 removed, bridges `D3cold to D0, device inaccessible`). Charging is fine. A PCI remove/rescan doesn't revive it.
