# Reading suspend symptoms on Macs

## Where to look
- `journalctl -b -1 -o short-monotonic | grep -E 'PM:|ACPI: PM|Waking up'`: the previous boot. If its last PM line is `suspend entry`, resume failed hard and nothing could be logged.
- `cat /proc/acpi/wakeup`: wake sources. Common Mac names: `LID0` lid, `EC` embedded controller (lid and power events on s2idle), `PWRB` power button, `XHC1/XHC2` USB controllers, `RP0x` PCIe root ports, `ARPT` Wi-Fi (AirPort), `SPIT` SPI keyboard/trackpad (2016–2017), `ADP1` charger.
- `cat /sys/power/mem_sleep`: the bracketed mode is current. `deep` = S3, `s2idle` = suspend-to-idle.
- `sudo sh -c 'echo devices > /sys/power/pm_test; echo deep > /sys/power/mem_sleep; echo mem > /sys/power/state'`: dry-run suspend up to the device stage, and the journal shows how long each stage took. Reset with `echo none > /sys/power/pm_test`. Use this to find the slow device without risking a hang.

## Patterns
| You see | Meaning |
|---|---|
| boot ends at `PM: suspend entry (deep)`, next boot is fresh | hard resume failure. On 2016–2017 MBP, start with the NVMe D3cold fix |
| `suspend entry` then `suspend exit` 1–3 s later, lid still closed | a wake source fired. Disable USB/PCIe/Wi-Fi wake |
| entry/exit pairs every ~30 s with the lid closed | the lid is pressing the keyboard (SPIT). Disable SPIT, keep LID0 and EC |
| `pcieport 0000:05:0x.0: Unable to change power state from D3cold to D0` | Thunderbolt bridges powered off. `--thunderbolt` speeds resume up, but USB-C data may still die |
| `applespi: Received corrupted packet` after resume | `--applespi-hook` |
| resume works but `nvme ... timeout` / I/O errors | NVMe D3cold again. Check `d3cold_allowed` is 0 after boot (the udev rule matches by ID) |
| deep fails even with all of the above | use s2idle. Some Mac firmware never completes S3 resume under Linux |

## Model generations (rough guide)
- **2015 and earlier** (SATA/AHCI or Samsung NVMe, USB keyboard): deep sleep usually works out of the box. If it wakes immediately, `XHC1` or `LID0` with the lid open is the usual cause.
- **2016–2017 MacBook Pro** (Apple S3X NVMe, SPI keyboard, Thunderbolt 3): everything in the fix table may be needed. See mbp-2016-linux.
- **T2 (2018+)**: different stack (`apple-bce`). Sleep support depends on the t2linux kernel; see t2linux.org instead.
