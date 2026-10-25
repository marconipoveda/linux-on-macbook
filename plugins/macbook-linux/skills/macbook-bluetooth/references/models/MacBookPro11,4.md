# MacBookPro11,4 (15" Mid 2015) — checked 2026-10-24, Ubuntu 26.04, kernel 7.0.0-38

Hardware: Broadcom Bluetooth on **internal USB** (`05ac:8290`), driver `btusb` + `btbcm`. Not UART, so the apple-hci-uart patch does not apply here.

- 9 of 10 logged boots ok. The one failure (after a warm reboot) was `hci0: command 0x0c03 tx timeout` / `BCM: Reset failed (-110)`, the chip not answering HCI Reset.
- No action taken. Untested workaround if it recurs: `sudo modprobe -r btusb && sudo modprobe btusb`, otherwise a full power-off.
