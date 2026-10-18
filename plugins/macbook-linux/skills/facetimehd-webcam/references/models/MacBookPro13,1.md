# MacBookPro13,1 (13" 2016)

- Camera: `14e4:1570` at PCI 03:00.0, no driver out of the box.
- Verified 2026-10-18: Ubuntu 26.04, kernel 7.0.0-38, facetimehd tag 0.7.2 via DKMS, firmware 5.60.0 plus 11 sensor files.
  `/dev/video0` gives YUYV 1296×736 at 30 fps and shows up in PipeWire; browsers (snaps) see it.
- Harmless in the kernel log: `Failed to lock S2 PLL: 0xc902c902` followed by `DDR40 PHY PLL locked on safe settings`.
- Not verified yet: suspend/resume with the camera; whether the 99facetimehd sleep hook is needed.
