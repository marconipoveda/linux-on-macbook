#!/bin/bash
# Install keyd and a Mac-style config. Root required; the user runs this in their own terminal:
#   sudo bash install.sh /path/to/mac-keys.conf
# Logs to ./mac-keyboard-install.log next to the config so the result can be checked afterwards.
set -e
CONF="$(readlink -f "${1:?usage: sudo bash install.sh /path/to/mac-keys.conf}")"
LOG="$(dirname "$CONF")/mac-keyboard-install.log"
exec > >(tee "$LOG") 2>&1
echo "== $(date)"
[ "$EUID" -eq 0 ] || { echo "ERROR: run with sudo"; exit 1; }
[ -r "$CONF" ] || { echo "ERROR: config not found: $CONF"; exit 1; }
. /etc/os-release

have_keyd() { command -v keyd >/dev/null || command -v keyd.rvaiya >/dev/null; }
if ! have_keyd; then
  echo "== installing keyd"
  if command -v apt-get >/dev/null; then
    apt-get update && apt-get install -y keyd || true
  elif command -v pacman >/dev/null; then
    pacman -S --noconfirm --needed keyd || true
  elif command -v dnf >/dev/null; then
    dnf install -y keyd || { dnf install -y dnf-plugins-core && dnf copr enable -y alternateved/keyd && dnf install -y keyd; } || true
  fi
  if ! have_keyd; then
    echo "== no package available, building keyd v2.5.0 from source"
    if command -v apt-get >/dev/null; then apt-get install -y git make gcc
    elif command -v dnf >/dev/null; then dnf install -y git make gcc
    elif command -v pacman >/dev/null; then pacman -S --noconfirm --needed git make gcc
    elif command -v zypper >/dev/null; then zypper -n in git make gcc
    fi
    SRC=$(mktemp -d)
    git clone --depth 1 --branch v2.5.0 https://github.com/rvaiya/keyd "$SRC/keyd"
    make -C "$SRC/keyd" && make -C "$SRC/keyd" install
  fi
fi
have_keyd || { echo "ERROR: keyd could not be installed"; exit 1; }
echo "keyd binary: $(command -v keyd || command -v keyd.rvaiya)"

mkdir -p /etc/keyd
if [ -f /etc/keyd/default.conf ] && ! cmp -s /etc/keyd/default.conf "$CONF"; then
  BAK="/etc/keyd/default.conf.bak.$(date +%s)"; cp /etc/keyd/default.conf "$BAK"; echo "backup: $BAK"
fi
install -m 644 "$CONF" /etc/keyd/default.conf

# Restart rather than "keyd reload": packages often start keyd before the config exists,
# and the reload command name differs between distros (keyd vs keyd.rvaiya).
systemctl enable keyd
systemctl restart keyd
sleep 1
echo "== service: $(systemctl is-active keyd)"
journalctl -u keyd --since "-10s" --no-pager | tail -n 20
if journalctl -u keyd --since "-10s" --no-pager | grep -qi 'error\|invalid'; then
  echo "RESULT: CONFIG ERROR (see lines above)"
elif journalctl -u keyd --since "-10s" --no-pager | grep -q 'DEVICE: match'; then
  echo "RESULT: OK"
else
  echo "RESULT: keyd running but no keyboard matched"
fi
