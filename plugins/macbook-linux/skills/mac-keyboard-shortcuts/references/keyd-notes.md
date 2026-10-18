# keyd syntax notes (v2.5)

- Config lives in `/etc/keyd/*.conf`; `[ids]` with `*` matches every keyboard (internal and external).
  To limit to one keyboard use its `vendor:product` id from `keyd monitor` (binary may be `keyd.rvaiya`).
- `[name:C]` declares a layer that acts as the Ctrl modifier for unbound keys. Keys bound inside it are
  sent exactly as written, without the Ctrl.
- `[cmd+shift]` / `[cmd+control]` are composite layers: active when both are held.
- Key names are physical US positions, regardless of the XKB layout: `` ` `` is the key left of 1
  (it's `|` or `º` on Spanish layouts), `grave` in a key sequence. List valid names: `keyd list-keys`.
- `M-` Super, `C-` Ctrl, `A-` Alt, `S-` Shift, `G-` AltGr. Example: `C-S-t`.
- `macro(S-home backspace)` sends a sequence. `swapm(layer, keys)` swaps to another layer while held
  and sends keys; used for Cmd+Tab so the switcher stays open.
- After editing: `sudo systemctl restart keyd`, then `journalctl -u keyd -n 20` to see parse errors and
  `DEVICE: match` lines.
- Emergency escape if a config makes the keyboard unusable: Backspace+Escape+Enter pressed together
  kills keyd.
