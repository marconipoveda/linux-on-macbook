# MacBookPro13,1 (13" 2016)

- BCM4350 `14e4:43a3` on brcmfmac. Works with the generic firmware brcmfmac4350c2-pcie.bin; the board .txt, .clm_blob and .txcap_blob are missing.
- broadcom-sta 6.30.223.271 (DKMS) was installed. It crashed on every boot (wl_module_init WARNING, code 13). Removed 2026-10-18; Wi-Fi unaffected.
- One boot (2026-10-18 18:54) had brcmfmac `MMIO read failed` and Bluetooth failed too, right after a wl crash.
