#!/bin/bash
# Read-only hardware report for a Mac running Linux. Needs no root (some sections are richer with it).
# Usage: bash scan.sh > scan-$(cat /sys/class/dmi/id/product_name).txt
# Mask MAC addresses (except all-zero, which is a useful Bluetooth symptom) and the hostname,
# so the report can be pasted into a public issue or model page.
HOST=$(hostname)
exec > >(perl -pe 's/\b((?:[0-9a-f]{2}:){5}[0-9a-f]{2})\b/$1 eq "00:00:00:00:00:00" ? $1 : "xx:xx:xx:xx:xx:xx"/gie; s/\Q'"$HOST"'\E/<hostname>/g')
sec() { printf '\n===== %s =====\n' "$1"; }
run() { command -v "${1%% *}" >/dev/null 2>&1 && eval "$1" 2>&1 || echo "($1: not available)"; }

sec "System"
for f in sys_vendor product_name product_version board_name bios_version bios_date; do
  printf '%-16s %s\n' "$f" "$(cat /sys/class/dmi/id/$f 2>/dev/null)"; done
. /etc/os-release 2>/dev/null; echo "os               $PRETTY_NAME"
echo "kernel           $(uname -r)"
echo "desktop          ${XDG_CURRENT_DESKTOP:-?} / ${XDG_SESSION_TYPE:-?}"
echo "cmdline          $(cat /proc/cmdline)"

sec "CPU / memory";   run "lscpu | grep -E 'Model name|^CPU\(s\)|MHz'"; run "free -h"
grep -H . /sys/devices/system/cpu/cpu0/cpufreq/{scaling_driver,scaling_governor,energy_performance_preference} 2>/dev/null

sec "PCI devices + drivers"; run "lspci -nnk"
sec "USB devices";           run "lsusb"
sec "Input devices";  awk -v RS= '{match($0,/Name="[^"]*"/); n=substr($0,RSTART,RLENGTH); match($0,/Handlers=[^\n]*/); print n "  " substr($0,RSTART,RLENGTH)}' /proc/bus/input/devices
sec "Loaded modules (Apple/Broadcom/camera/audio)"; lsmod | grep -iE 'apple|bcm|brcm|wl|facetime|snd_hda|cs8409|thunderbolt|i915|amdgpu|radeon|nouveau|hid_apple|applespi|bce' || true
sec "DKMS";            run "dkms status"
sec "Display / GPU";   ls /sys/class/backlight/ 2>/dev/null | sed 's/^/backlight: /'
for b in /sys/class/backlight/*; do [ -r $b/max_brightness ] && echo "$b max=$(cat $b/max_brightness) now=$(cat $b/brightness)"; done
ls /sys/class/leds/ 2>/dev/null | grep -i kbd | sed 's/^/kbd backlight: /'
sec "Storage";         run "lsblk -o NAME,SIZE,MODEL,TRAN"
sec "Network";         run "ip -br link"; run "nmcli -t -f DEVICE,TYPE,STATE dev"; run "rfkill list"
sec "Bluetooth";       run "bluetoothctl show"; ls /sys/class/bluetooth/ 2>/dev/null
sec "Webcam";          ls -l /dev/video* 2>/dev/null || echo "no /dev/video*"; run "v4l2-ctl --list-devices"
sec "Audio";           run "aplay -l"; run "pactl list short sinks"; run "pactl list short sources"
sec "Battery / power"
for p in /sys/class/power_supply/*; do echo "-- $p"; grep -sH . $p/{type,status,capacity,cycle_count,charge_full,charge_full_design,energy_full,energy_full_design,online} 2>/dev/null | sed "s|$p/||"; done
sec "Sleep";           echo "mem_sleep: $(cat /sys/power/mem_sleep 2>/dev/null)"; echo "state: $(cat /sys/power/state 2>/dev/null)"
grep -E 'enabled' /proc/acpi/wakeup 2>/dev/null | sed 's/^/wakeup enabled: /'
sec "Thermal / SMC";   ls /sys/devices/platform/applesmc.768/ 2>/dev/null | grep -E 'fan[0-9]_(input|min|max)$|light' | while read f; do echo "$f=$(cat /sys/devices/platform/applesmc.768/$f 2>/dev/null)"; done
run "sensors"
sec "Power services";  for s in power-profiles-daemon tlp thermald mbpfan auto-cpufreq; do printf '%-22s %s\n' $s "$(systemctl is-active $s 2>/dev/null)"; done
sec "Packages of note"
if command -v dpkg >/dev/null; then dpkg -l 2>/dev/null | awk '/^ii/ && $2 ~ /broadcom|bcmwl|firmware|microcode|facetime|mbpfan|keyd/ {print $2, $3}'
elif command -v rpm >/dev/null; then rpm -qa | grep -iE 'broadcom|wl|firmware|microcode|facetime|mbpfan|keyd'; fi
sec "Kernel log: errors, warnings, missing firmware (this boot)"
{ journalctl -k -b --no-pager 2>/dev/null || dmesg 2>/dev/null; } | grep -iE 'error|fail|warn|firmware|direct firmware load|call trace|taint' | grep -v 'audit' | tail -n 120
echo; echo "(end of scan)"
