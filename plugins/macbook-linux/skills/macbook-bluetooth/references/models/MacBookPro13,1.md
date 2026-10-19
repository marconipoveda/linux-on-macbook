# MacBookPro13,1 (13" 2016) — status 2026-10-18, Ubuntu 26.04, kernel 7.0.0-38

Hardware: BCM4350C0 Bluetooth on the LPSS UART (ACPI BCM2E7C, `hci_uart_bcm`), the same chip as the BCM4350 Wi-Fi (`14e4:43a3`, brcmfmac).

- Stock driver: intermittent. 35 boots, about 1/3 failed (`0xfc18 tx timeout`). Failures were more frequent after warm reboots (7/16) than after power-offs (2/8), and also happened before broadcom-sta was installed.
- apple-hci-uart 1.0 (DKMS) installed 2026-10-18 18:40. The patch applies cleanly to Ubuntu's linux-source-7.0.0 (7.0.0-38.38).
  Boots since (as of 2026-10-18 19:29): 5 ok, 1 fail. The fail coincided with a wl crash plus a Wi-Fi failure (`brcmfmac: MMIO read failed`).
- broadcom-sta removed 2026-10-18 19:05. Boots since then: **5 of 5 ok** (19:05, 19:09, 19:29, 19:34, 19:37, mostly warm restarts). Considered fixed on 2026-10-18.
- Which change mattered more is unknown: the patch alone (with wl present) gave 4 ok / 1 fail, and wl removal came next. Keep both. If failures return, run retry-bt.sh on the failed boot and reopen.
- retry-bt.sh (driver reload) not yet tested on a failed boot.
- Audio: a KBS-030 speaker plays over A2DP SBC. Choppy audio occurred with Wi-Fi on 2.4 GHz channel 1, Settings open (scanning) and headphones connected at the same time.
