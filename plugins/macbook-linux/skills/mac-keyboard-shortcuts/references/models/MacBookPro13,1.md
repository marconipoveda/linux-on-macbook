# MacBookPro13,1 (13" 2016, function keys)

- Keyboard is "Apple SPI Keyboard" (applespi driver), vendor:product 0000:0000. keyd's `[ids] *` matches it.
- Tested 2026-10-18: Ubuntu 26.04, GNOME 50 Wayland, keyd 2.5.0-5 (binary `keyd.rvaiya`), latam layout. All shortcuts work.
- The apt package starts keyd before the config is copied, so the installer must restart keyd afterwards. `install.sh` does this.
