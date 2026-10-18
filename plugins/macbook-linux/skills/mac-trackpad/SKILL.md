---
name: mac-trackpad
description: Make a MacBook trackpad on Linux behave like on macOS. Turns off tap-to-click (light touches clicking things by accident), makes a press click and a two-finger press right-click instead of bottom-corner areas, and tunes scrolling direction, pointer acceleration and palm rejection. Use this whenever someone on Linux with a MacBook or Magic Trackpad complains that the trackpad clicks when they only touch it, that right-click doesn't work like on a Mac, that the pointer feels slow or wrong compared to macOS, or that their palm moves the cursor while typing. Also use it if they ask to "fix the touchpad" on a Mac.
---

# Mac-style trackpad on Linux

Linux desktops often ship with **tap-to-click on** and **right-click in the bottom-right corner**, which is the opposite of macOS. Mac users then trigger clicks by brushing the pad, and can't find right-click. Every desktop exposes the underlying libinput settings, so this is a settings change, not a driver fix. Everything here is reversible and needs no root on GNOME or KDE.

## 1. Find out what's annoying and what's running

Ask, or infer from the message, which behavior bothers the person: accidental tap clicks, right-click, scroll direction, speed or acceleration, or the palm moving the cursor. Change only what they asked for, plus the click method, which goes hand in hand with turning taps off. Then check:

- desktop: `echo $XDG_CURRENT_DESKTOP $XDG_SESSION_TYPE`
- the trackpad and its driver: `grep -A1 -i touchpad /proc/bus/input/devices`. Expect `bcm5974` (USB, up to 2015), `applespi` (2016–2017) or `apple-bce`/`hid-magicmouse` (T2, 2018+).
- if `references/models/<product_name>.md` exists (`cat /sys/class/dmi/id/product_name`), read it

## 2. Apply

**GNOME:** `bash scripts/gnome-trackpad.sh`. It turns tap-to-click off and sets `click-method` to `fingers`: one finger pressing is a click, two is a right-click, three is a middle-click. The change applies immediately and an undo script is saved first. Options:
- `--keep-tap`: keep tapping and fix only the right-click
- `--accel adaptive`: pointer acceleration closer to macOS (`flat` is constant speed)

**KDE Plasma:** System Settings → Mouse & Touchpad → Touchpad → select the Apple trackpad:
- uncheck *Tap-to-click*
- set *Right-click* to *Press anywhere with two fingers*

The settings are per device and live in `~/.config/kcminputrc`. Guide the person through the UI rather than editing that file: the group names include device IDs, and KWin only picks up file edits after a re-login.

**Other desktops on Wayland:** use that desktop's touchpad settings (Cinnamon, Budgie and others offer the same two options).

**X11 without a settings UI:** a libinput snippet. It needs root, so the person installs it and then logs out and back in:
```
# /etc/X11/xorg.conf.d/30-mac-trackpad.conf
Section "InputClass"
    Identifier "Mac trackpad"
    MatchIsTouchpad "on"
    Driver "libinput"
    Option "Tapping" "off"
    Option "ClickMethod" "clickfinger"
EndSection
```

## 3. Verify with the person

Have them try three things:
1. A light tap should do nothing.
2. A firm press with one finger should click.
3. A firm press with two fingers should right-click.

**Pressing has to work before tapping is gone for good.** If a press doesn't register, the person is left with no way to click, so undo straight away: `bash ~/.config/mac-trackpad/undo.sh`. Then check the driver; the trackpad may only be partly supported on that model.

Force Touch trackpads (2015 13" and later) give no haptic "click" feel on Linux. The press still registers. Tell the person this up front, so a silent press doesn't look like a failure.

## Other common complaints

- **Scrolling direction:** "natural" scrolling (content follows the fingers) is the macOS default. On GNOME: `gsettings set org.gnome.desktop.peripherals.touchpad natural-scroll true`.
- **Palm moves the cursor while typing:** check `disable-while-typing` on GNOME, or *Disable while typing* on KDE. If that's already on and the palm still gets through, it's hardware-specific: note the model and the driver, and look in `references/models/`.
- **Garbled trackpad after resume** (applespi models): that's a sleep issue, not a setting. It's fixed by reloading `applespi` in a system-sleep hook. See the macbook-sleep skill.
