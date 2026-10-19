---
name: mac-trackpad
description: Make a MacBook trackpad and pointer on Linux feel like macOS. Turns off tap-to-click (light touches clicking things by accident) and sets press-to-click with two-finger right-click; tunes pointer speed and acceleration; slows down two-finger scrolling that's far too fast (GNOME has no setting for it); stops web pages gliding after you lift your fingers; and installs a macOS-style cursor. Use this whenever someone on Linux with a MacBook or Magic Trackpad complains that the trackpad clicks when they only touch it, right-click doesn't work like on a Mac, the pointer is too fast, too slow or laggy, scrolling is too fast or too sensitive, pages keep scrolling after lifting their fingers, or wants the Mac cursor. Also use it for "fix the touchpad" on a Mac.
---

# Mac-style trackpad and pointer on Linux

Linux desktops often ship with **tap-to-click on** and **right-click in the bottom-right corner**, the opposite of macOS. Pointer and scroll speeds also feel different from a Mac's. Most of this is libinput settings that the desktop exposes. Two things aren't: **scroll speed**, which GNOME has no setting for, and **the browser's glide**, which the browser controls.

Work through one complaint at a time and let the person try each change before moving on. "Too fast", "too sensitive" and "lags" each have several possible causes, and the fix depends on which one it is.

## 0. Look first

- Desktop: `echo $XDG_CURRENT_DESKTOP $XDG_SESSION_TYPE`.
- Trackpad and driver: `grep -A1 -i touchpad /proc/bus/input/devices`. Expect `bcm5974` (USB, up to 2015), `applespi` (2016–2017) or `apple-bce`/`hid-magicmouse` (T2, 2018+).
- Current settings on GNOME: `gsettings list-recursively org.gnome.desktop.peripherals.touchpad`.
- The display scale (Settings → Displays). Fractional scaling such as 125% affects how fast everything feels, and how smooth the pointer is.
- If `references/models/<product_name>.md` exists (`cat /sys/class/dmi/id/product_name`), read it.

All GNOME settings here apply immediately and need no root. Each script saves an undo file first, in `~/.config/mac-trackpad/`.

## 1. Clicking

**GNOME:** `bash scripts/gnome-trackpad.sh`. It sets tap-to-click off and `click-method` to `fingers`: one finger pressing = click, two = right-click, three = middle-click. Use `--keep-tap` to fix only right-click.

**KDE Plasma:** System Settings → Mouse & Touchpad → Touchpad → the Apple trackpad: uncheck *Tap-to-click*, and set *Right-click* to *Press anywhere with two fingers*. Guide the person through the UI rather than editing `kcminputrc`, whose group names include device IDs.

**X11 without a settings UI:** create `/etc/X11/xorg.conf.d/30-mac-trackpad.conf` (root), then log out and back in:
```
Section "InputClass"
    Identifier "Mac trackpad"
    MatchIsTouchpad "on"
    Driver "libinput"
    Option "Tapping" "off"
    Option "ClickMethod" "clickfinger"
EndSection
```

**Pressing must work before tapping is gone.** Have the person try a light tap (nothing should happen), a firm one-finger press (click) and a two-finger press (right-click). If a press doesn't click, undo immediately (`bash ~/.config/mac-trackpad/undo.sh`), or they're left with no way to click. Force Touch trackpads (2015 13" and later) give no haptic "click" feel on Linux; the press still registers. Say so up front.

## 2. Pointer speed and feel

GNOME's two knobs are `speed` (-1 to 1) and `accel-profile`:
- **`flat`**: constant ratio between finger and pointer. Precise, but small movements can feel jumpy at higher speeds.
- **`adaptive`**: slow finger movements give fine control and quick flicks travel far, like macOS.

Use `bash scripts/gnome-trackpad.sh --accel adaptive --speed 0.4`, or change one value at a time with `gsettings set org.gnome.desktop.peripherals.touchpad speed <n>`. Move in steps of about 0.2 and let the person try each.

**Interactions to know about:**
- On touchpads, libinput applies acceleration to two-finger scrolling too. Switching to `adaptive` can make scrolling much faster. If the person then complains about scrolling, fix the scroll speed (step 3) rather than giving up on adaptive. Once the scroll factor was in place on MacBookPro13,1, adaptive was the preferred setting.
- The scroll fix (step 3) also slows the pointer by the same factor. Compensate by raising `speed`, which tops out at 1.

**"The pointer lags":** tell these apart before changing anything:
1. **adaptive's slowdown on small movements**, which feels like lag. Test with `flat` for a minute.
2. **Discarded touch jumps**: `journalctl -b | grep "Touch jump detected"`. A few per session are normal with `applespi`. Dozens are worth a libinput quirk.
3. **The compositor can't keep up**: check `gnome-shell` CPU in `top`. Fractional scaling (125%, 150%) on a 2560×1600 panel with Intel graphics is expensive. Test 100% or 200% scaling for a minute.

## 3. Scroll speed (GNOME has no setting)

GNOME has no scroll-speed option, and the upstream work has been stuck for years. Say this up front, so nobody hunts for a hidden setting. The robust fix is a **hwdb resolution override**: it tells libinput the trackpad has more units per mm, so the same finger movement counts as less distance. It's a plain system config file, with no code injected into the compositor, and it survives GNOME updates.

```bash
sudo bash scripts/slower-scroll.sh 2        # half the scroll speed; then REBOOT
sudo bash scripts/slower-scroll.sh 3        # stronger (re-run with any factor; the original values are remembered)
sudo bash scripts/slower-scroll.sh --remove # undo, then reboot
```

The script finds the trackpad, reads its current resolution (systemd's own `60-evdev.hwdb` usually already sets one for Apple trackpads, readable via `udevadm info`), and writes `/etc/udev/hwdb.d/61-macbook-touchpad-scroll.hwdb`, which takes precedence. It must run as root, and it takes effect after a reboot, because libinput reads these properties only when the device appears.

Afterwards:
1. Verify with `udevadm info /dev/input/eventN | grep EVDEV_ABS`. It should show the scaled values.
2. The pointer is now slower by the same factor. Raise `speed`: on flat, -0.3 → about 0.7 for factor 2.
3. Factor 3 is about the practical maximum. Beyond it, even `speed 1` can't bring the pointer back.
4. Side effect: libinput now thinks the pad is smaller in mm, so palm and edge thresholds get stricter. That hasn't caused trouble at factor 2.

Alternatives, if the hwdb route isn't wanted: `libinput-config` (`scroll-factor=` in `/etc/libinput.conf`, an LD_PRELOAD into the compositor) and *Wayland Scroll Factor* (an alpha per-user tool). Both hook into the compositor, and users report they sometimes do nothing on newer stacks. On X11, the libinput option `ScrollPixelDistance` does this directly.

## 4. "It keeps scrolling after I lift my fingers"

That's **kinetic scrolling** (fling), done by the app, not the system. It's also why a person may say they "have to move extremely slowly": any normal swipe gets thrown. A system scroll factor can't remove it. Ask which app:

- **Firefox:** in `about:config`, set `apz.gtk.kinetic_scroll.enabled` = `false` (create it as a Boolean if missing) to switch the glide off. Or keep it, and raise `apz.fling_friction` (e.g. to 0.9) so it stops sooner.
- **Chrome / Brave / other Chromium:** as of 2026 there's no setting to disable the glide on Linux; there's an open Chromium request. Lowering the overall scroll speed (step 3) shortens the glide. Say plainly that there's no switch, rather than suggesting flags that don't exist.
- **GTK apps** (Files, Settings): the glide follows the toolkit, and there's no user setting.

## 5. macOS cursor

`bash scripts/mac-cursor.sh [macOS|macOS-White] [size]` installs [apple_cursor](https://github.com/ful1e5/apple_cursor) v2.0.1 (GPL-3.0, an open-source recreation, not Apple's files) into `~/.local/share/icons` and selects it on GNOME. The script checks the download size, verifies the archive, and refuses unsafe paths or links. Browsers pick up the new cursor after a restart; other stubborn apps after logging out and back in. Size 24 is the default; try 32 on high-DPI screens. Undo: `bash ~/.config/mac-trackpad/undo-cursor.sh`. On other desktops, run the script and then pick the theme in the cursor settings.

## Other common complaints

- **Scroll direction:** "natural" (content follows the fingers) is the macOS default: `gsettings set org.gnome.desktop.peripherals.touchpad natural-scroll true`.
- **Palm moves the cursor while typing:** make sure `disable-while-typing` is on. If the palm still gets through, note the model and driver, and check `references/models/`.
- **Garbled trackpad after resume** (applespi models): a sleep issue, fixed by reloading `applespi` in a system-sleep hook. See the macbook-sleep skill.
