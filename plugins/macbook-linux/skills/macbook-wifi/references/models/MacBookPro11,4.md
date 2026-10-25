# MacBookPro11,4 (15" Mid 2015)

- BCM43602 `14e4:43ba` (subsystem `106b:0152`) on brcmfmac, firmware `brcmfmac43602-pcie.bin` 7.35.177.61. The board `.bin`/`.txt`, `.clm_blob` and `.txcap_blob` are missing (normal).
- No broadcom-sta/wl installed. Checked 2026-10-24: 5 GHz, 80 MHz, 540/1300 Mbit/s at -48 dBm.
- brcmfmac re-probes the card on every S3 resume (the interface is renamed again from `wlan0`) and reconnects by itself.
