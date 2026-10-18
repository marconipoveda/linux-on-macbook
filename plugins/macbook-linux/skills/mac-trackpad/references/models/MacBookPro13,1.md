# MacBookPro13,1 (13" 2016)

- Trackpad: "Apple SPI Touchpad" (Force Touch), driver applespi.
- Verified 2026-10-18 on GNOME 50 Wayland: tap-to-click off and click-method fingers work. Press = click, two-finger press = right-click. No haptic feedback.
- Ubuntu's default accel-profile was `flat`.
- After resume the trackpad can come back garbled until applespi is reloaded (sleep hook).
