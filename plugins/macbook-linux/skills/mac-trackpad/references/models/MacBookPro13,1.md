# MacBookPro13,1 (13" 2016)

Trackpad: "Apple SPI Touchpad" (Force Touch), driver applespi, `/dev/input/event5`. No haptic feedback on Linux.
Display: 2560×1600 at 125% fractional scaling on Ubuntu's defaults.

Verified 2026-10-18 (Ubuntu 26.04, GNOME 50 Wayland, libinput 1.31.1). Final settings the owner kept:
- tap-to-click off, click-method fingers
- scroll factor 2 (`slower-scroll.sh 2`): resolution 96/94 → 192/188 units/mm. The original 96/94 comes from systemd's 60-evdev.hwdb.
- accel-profile adaptive, speed 0.4 (after the scroll factor). Before the factor, adaptive made two-finger scrolling far too fast; flat at 0.7 also worked well.
- cursor theme macOS (apple_cursor v2.0.1), size 24

How we got there, so others can skip steps:
1. Ubuntu's default was flat at speed 0, which felt too fast and jumpy.
2. Adaptive at -0.2 fixed the pointer, but scrolling became much too fast.
3. Flat at -0.3: the pointer was OK, but scrolling was still too fast (with the browser glide on top).
4. Scroll factor 2 and a reboot: scrolling fine, pointer too slow. Raised speed to 0.7 (flat), later switched to adaptive at 0.4.

`Touch jump detected and discarded` shows up a couple of times per session (applespi). Harmless at that rate.
