#!/bin/bash
# Bluetooth (BCM, UART or USB) result for each logged boot. Read-only, normal user.
# Usage: bash check-boots.sh ["YYYY-MM-DD HH:MM"]   only count boots starting after that time
SINCE="${1:-0000}"
ok=0; bad=0
journalctl --list-boots --no-pager -o json 2>/dev/null | python3 -I -c '
import json, sys, datetime
for b in json.load(sys.stdin):
    t = datetime.datetime.fromtimestamp(b["first_entry"] / 1e6).strftime("%Y-%m-%d %H:%M:%S")
    print(b["index"], t)' | while read -r idx d t; do
  [[ "$d $t" < "$SINCE" ]] && continue
  k=$(journalctl -k -b "$idx" --no-pager 2>/dev/null)
  if grep -q 'hci0: command .* tx timeout\|BCM: Reset failed' <<<"$k"; then r=FAIL
  elif grep -q 'hci0: BCM: chip id' <<<"$k"; then r=ok
  else r=-; fi
  wifi=$(grep -q 'brcmfmac.*MMIO read failed\|brcmf_pcie_probe: failed' <<<"$k" && echo " (Wi-Fi also failed)")
  printf 'boot %4s  %s %s  %s%s\n' "$idx" "$d" "$t" "$r" "$wifi"
done | tee /dev/stderr | awk '$5=="ok"{o++} $5=="FAIL"{f++} END{printf "total: ok=%d fail=%d\n", o, f}' 1>&2
