---
name: mac-keyboard-shortcuts
description: Make a Linux desktop use macOS keyboard shortcuts (Cmd+C/Cmd+V copy and paste, Cmd+Tab app switching, Cmd+Q, Cmd+Space search, Cmd/Option+arrow text navigation) by setting up keyd, a system-wide key remapper that works on Wayland and X11. Use this whenever someone runs Linux (Ubuntu, Debian, Fedora, Arch, Pop!_OS, Mint...) on a MacBook, iMac or with an Apple keyboard and wants the Command key to behave like on a Mac, says their muscle memory keeps hitting Cmd+C, asks for "mac keyboard layout/shortcuts on linux", or mentions Kinto, Toshy or keyd for Mac-style keys, even if they never say "keyd".
---

# Mac keyboard shortcuts on Linux

The goal: the person's Mac muscle memory just works. Cmd+C copies, Cmd+Tab switches apps, Option+← jumps a word. Their keyboard layout keeps working, including AltGr symbols on non-US layouts.

The approach is **keyd**, a small daemon that remaps keys at the kernel input level. It works on Wayland and X11 and in every app, and it needs no desktop extensions. Holding Cmd activates a layer that acts as Ctrl for everything (so every Ctrl shortcut in every app becomes a Cmd shortcut), plus a few explicit Mac-specific bindings (Cmd+Tab, Cmd+Q, Cmd+arrows...).

## Workflow

### 1. Detect the environment (read-only)

Run `bash scripts/detect.sh`. It reports the distro, desktop and session type, keyboards, layout(s), whether keyd is already installed and under which binary name, hid_apple kernel options, other remappers, and installed terminals.

Use the report to settle these questions:

- **Desktop**: GNOME, KDE Plasma, or other (XFCE, Cinnamon, MATE, Budgie...). This decides which modifier the app switcher uses and what Cmd+Space should send.
- **Layout**: US-style or one that needs AltGr (es, latam, de, fr, it, pt, pl, nordic...). On AltGr layouts the right Option key types symbols like `@ # [ ] { }`, so it must stay untouched.
- **Conflicts**: Kinto, Toshy, xremap, kmonad, kanata, input-remapper or interception-tools already running would double-remap keys. Ask the person before disabling any of them. Stopping and disabling is enough, and it's reversible: Kinto runs as the user service `xkeysnail.service`, and Toshy as `toshy-*.service` user units (`systemctl --user disable --now <unit>`). Point to the tool's own uninstaller only if the person wants it gone entirely.
- **hid_apple.swap_opt_cmd=1**: the kernel already swaps Option and Cmd. The config assumes Cmd is Super (the default), so ask whether to drop that option first, or adjust the config.
- **Keyboard missing from the list**: on T2 Macs (most 2018–2020 models), the internal keyboard only appears with the t2linux kernel or the `apple-bce` driver. Until it shows up, keyd has nothing to remap, so solve that first ([t2linux.org](https://t2linux.org)). External keyboards still work.
- **Model notes**: if `references/models/<product_name>.md` exists for this Mac, read it. It lists quirks found on that specific model.

If you're helping someone remotely, or can't run commands on their machine, ask them to paste the output of `detect.sh`.

### 2. Explain the plan and get a yes

Before you change anything, tell the person in plain words what will change: keyd gets installed, and these shortcuts change (show the relevant rows of `references/shortcuts.md`). Mention the trade-offs up front:

- **Terminals:** Cmd+C sends Ctrl+C, which interrupts the running program instead of copying. Copy and paste with Cmd+Shift+C / Cmd+Shift+V (and Cmd+Shift+T for a new tab). This holds in every common Linux terminal.
- Tapping Cmd alone no longer opens the overview or app menu. Cmd+Space does that instead.
- Physical Ctrl stays a normal Ctrl, as on a Mac.

### 3. Generate the config

```bash
bash scripts/make-config.sh <gnome|kde|other> > ~/mac-keyboard/mac-keys.conf
```

Add `--both-option-keys` **only** for US-style layouts. It gives the right Option key the same word-jump layer as the left one.

Put the files in a folder the person will find again (`~/mac-keyboard/` by default, or wherever they keep setup files). Show them the generated file and briefly explain it. If they ask for extra bindings, edit the generated file; `references/keyd-notes.md` covers the syntax rules that matter.

### 4. Root step: the person runs the installer

Installing needs root, and `sudo` usually can't prompt for a password inside an agent's shell. Don't try to run sudo yourself. Copy `scripts/install.sh` next to the config and ask the person to run it in their own terminal:

```bash
sudo bash ~/mac-keyboard/install.sh ~/mac-keyboard/mac-keys.conf
```

The script installs keyd through the distro's package manager. On Debian or Ubuntu that's `apt`, and the binary is named `keyd.rvaiya`. On Arch it's `pacman`. On Fedora it uses the `alternateved/keyd` COPR. Anywhere else it falls back to building v2.5.0 from source. It backs up any existing `/etc/keyd/default.conf`, installs the new one, and restarts the service. It writes `mac-keyboard-install.log` next to the config and ends with a `RESULT:` line.

If the person prefers to type commands themselves, give them the equivalent steps. Always end with `systemctl restart keyd`, not `keyd reload`: packages often start keyd before the config exists, and the reload command's name varies by distro.

### 5. Desktop tweaks (no root)

- **GNOME:** run `bash scripts/gnome-shortcuts.sh`. keyd turns Cmd+Space into Super+Space, which GNOME uses for switching keyboard layouts. The script rebinds Super+Space to Activities search. If the person has several layouts, it moves layout switching to Ctrl+Space, as on macOS. It saves an undo script first.
- **KDE Plasma:** nothing required. Cmd+Space sends Alt+Space, which opens KRunner. If the person has rebound Alt+Tab or Meta+PageDown, adjust the config to match.
- **Other desktops:** Cmd+Space sends a Super tap, which opens the menu on most desktops. Check that Alt+Tab is the window switcher in their settings.

### 6. Verify

Read the log. `RESULT: OK` and a `DEVICE: match ... <keyboard name>` line mean keyd picked up the keyboard. Then have the person try Cmd+C / Cmd+V in a text field, hold Cmd and tap Tab, try Cmd+Space, and try Option+← and →. On AltGr layouts, also check that right Option still types `@`. If something's off, see `references/troubleshooting.md`.

### 7. Wrap up

Tell the person:
- where the config lives, and that after editing it they re-run the installer (or `sudo systemctl restart keyd`)
- how to undo: `sudo bash uninstall.sh` (copy `scripts/uninstall.sh` alongside the others), plus the GNOME undo script if it ran
- the terminal copy/paste caveat, one more time

## Why these choices

- **keyd rather than Kinto or Toshy:** keyd is in the Debian, Ubuntu and Arch repos and has no desktop dependencies. It works the same on Wayland and X11 and survives desktop upgrades. Toshy and Kinto can tell apps apart (so Cmd+C copies even in a terminal), but they rely on per-desktop extensions that break often, especially on new GNOME releases. If the person really wants terminal-aware Cmd+C and accepts that fragility, Toshy is the tool to point them to. Say so rather than hacking it into keyd.
- **The `[cmd:C]` layer** makes every unlisted Cmd+key behave as Ctrl+key with Shift and Alt still applied, so Cmd+Shift+Z, Cmd+Shift+T and Cmd+Alt+I all behave as expected. Explicitly bound keys are sent without the Ctrl. That's why `left = home` produces Home, not Ctrl+Home.
- **`swapm(app_switch, ...)` for Cmd+Tab:** it keeps the switcher's modifier held for as long as Cmd is down, so the switcher stays open while you tap Tab. A plain `tab = M-tab` would flash the switcher and close it.
