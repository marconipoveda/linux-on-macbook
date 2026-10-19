# Bluetooth audio on Macs (BCM4350 and similar combo chips)

## "It says connected but there's no sound"
Three different "connected" indicators mislead people:
- **The speaker's own light or voice prompt**: connected to *some* device, often the phone.
- **GNOME Settings → Bluetooth**: lists every *paired* device. The button shows the action: **"Connect" means not connected**, "Disconnect" means connected.
- **Settings → Sound → Output**: only lists the device while it's really connected to this computer. This one is the reliable check.

Ground truth: `bluetoothctl info <MAC> | grep Connected`. Then check the default output: `pactl get-default-sink`. If it's still the built-in output, `pactl set-default-sink bluez_output.<MAC>` (or pick it in Sound settings).

## Speaker connected, but playback fails
Journal: `avdtp_parse_rej() START request rejected: Stream End Point in Use (19)`, plus wireplumber `Acquire ... returned error: org.bluez.Error.Failed`. The speaker still holds a stream: from pairing, or from another device (many speakers take only one audio source). Fix: disconnect the speaker from the phone, then `bluetoothctl disconnect <MAC> && bluetoothctl connect <MAC>`. Switching the card profile off and back on did **not** help; a full reconnect did.

Test without an app: `paplay -d bluez_output.<MAC> /usr/share/sounds/freedesktop/stereo/bell.oga`.

## Choppy audio, dropouts, video plays but sound stops
These chips share radio time between Bluetooth and 2.4 GHz Wi-Fi. In order of impact:
1. **Wi-Fi on 2.4 GHz.** Check `iw dev <wlan> link | grep freq`: 24xx = 2.4 GHz. Move to the router's 5 GHz network (often the same router with a different name). This is the biggest fix.
2. **Discovery running.** The GNOME Bluetooth settings page scans continuously while it's open (`bluetoothctl show` → `Discovering: yes`). Close Settings while listening.
3. **Several audio devices connected at once** (e.g. headphones and speaker). Disconnect the unused one.
4. After a dropout, pause and resume, or reconnect the device; the stream may not restart on its own.
Also check the active profile is A2DP (`pactl list cards | grep 'Active Profile'` → `a2dp-sink`), not HSP/HFP headset mode, which is mono and low quality.

## Reconnect after boot
Linux doesn't reconnect audio devices by itself at boot. Mark the device trusted (`bluetoothctl trust <MAC>`) so it may connect without a prompt. Then:
1. Most speakers reconnect to the *last* device they used when switched on: turn the speaker on after the computer has booted.
2. Or a user systemd service that runs `bluetoothctl connect <MAC>` a few times after login. It only helps if the device is already on at login.
3. `/etc/bluetooth/main.conf` `[Policy] ReconnectAttempts/ReconnectIntervals` cover lost links, not boot.
