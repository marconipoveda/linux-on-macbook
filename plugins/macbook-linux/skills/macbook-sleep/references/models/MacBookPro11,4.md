# MacBookPro11,4 (15" Mid 2015): no fixes needed (2026-10-25, Ubuntu 26.04, kernel 7.0)

Deep (S3) works out of the box. Aftermarket Samsung 970 EVO NVMe on an adapter; Boot ROM 489.0.0.0.0.

- 5 logged resumes clean, including 16.4 h overnight on battery: **0.1 %/h (~0.06 W)** asleep, no spurious wakes. Hibernation not needed.
- Wake sources at defaults: PEG0, PEG1, RP03, RP04, XHC1, ARPT, LID0. Lid or power button wakes it; keys don't (the xHCI root hub `usb1` has wakeup disabled).
- **Wake takes ~15 s** regardless of source (lid, power button, RTC alarm). Measured with an RTC alarm and `pm_print_times`: Linux's resume is under 2 s (noirq resume 1.08 s, almost all in `pcieport 0000:00:01.0`, the NVMe's root port; facetimehd 0.52 s; brcmfmac 0.18 s). Every suspend also shows a 14–18 s jump in kernel timestamps between `Filesystems sync` and `Freezing user space processes`, matching the wait. Conclusion: the time is in the firmware's S3 resume path. Suspected cause, not proven: firmware re-initializing a non-Apple NVMe. s2idle (which skips it) not tested; the owner preferred deep sleep's low drain.
- One boot (2026-10-10) ended on `suspend entry` and the next boot's clock had reset to July: most likely the battery ran flat during a ~2-week sleep, not a failed resume.
