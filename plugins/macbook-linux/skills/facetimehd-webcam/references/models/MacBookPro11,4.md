# MacBookPro11,4 (15" Mid 2015)

- Camera: `14e4:1570` at PCI 04:00.0, no driver out of the box. No Secure Boot on this Mac.
- Verified 2026-10-24: Ubuntu 26.04, kernel 7.0.0-38, facetimehd tag 0.7.2 via DKMS, firmware plus 11 sensor files. `/dev/video0` appeared right after install, no reboot; 1280×720 test frame fine, shows up in PipeWire.
- Survives deep (S3) suspend: the driver reloads its firmware on resume by itself, so the 99facetimehd hook isn't needed. It adds about 0.5 s to resume.
