#!/bin/bash
# Hibernation and suspend-then-hibernate for Macs. Root required; the person runs it in their own terminal.
# Do the steps in order, testing in between:
#
#   sudo bash hibernate.sh --status                 what is set up, and what would block hibernation
#   sudo bash hibernate.sh --setup                  swap >= RAM, resume= and resume_offset=, initramfs; then reboot
#   sudo bash hibernate.sh --allow                  undo Ubuntu's polkit block on hibernation (no reboot)
#   sudo bash hibernate.sh --unload "brcmfmac_wcc brcmfmac"
#                                                   unload these modules before hibernating, reload after
#   sudo bash hibernate.sh --test                   hibernate and restore at once, no power-off (test_resume)
#   sudo bash hibernate.sh --lid 10min              lid on battery: sleep, then hibernate after the delay;
#                                                   on the charger: sleep only. Reboot after the first time
#   sudo bash hibernate.sh --grub-no-wait           no 30 s hidden boot menu after a hibernation (Ubuntu GRUB)
set -euo pipefail
[[ $EUID -eq 0 ]] || { echo "Run with sudo"; exit 1; }
[ $# -gt 0 ] || { sed -n 2,15p "$0"; exit 1; }
HOOK=/usr/lib/systemd/system-sleep/40-macbook-hibernate
UNLOAD=/etc/macbook-sleep/hibernate-unload

status() {
  echo "kernel: $(uname -r)   lockdown: $(cat /sys/kernel/security/lockdown 2>/dev/null || echo n/a)"
  grep -q '\[integrity\]\|\[confidentiality\]' /sys/kernel/security/lockdown 2>/dev/null &&
    echo "  BLOCKER: kernel lockdown (usually Secure Boot) forbids hibernation"
  echo "disk modes: $(cat /sys/power/disk)"
  echo "RAM: $(awk '/MemTotal/{printf "%.1f GiB", $2/1048576}' /proc/meminfo)"
  swapon --show --bytes | sed 's/^/  /'
  echo "cmdline: $(grep -oE 'resume(_offset)?=[^ ]+' /proc/cmdline | tr '\n' ' ')"
  echo "kernel resume device: $(cat /sys/power/resume) offset $(cat /sys/power/resume_offset 2>/dev/null)"
  for a in CanHibernate CanSuspendThenHibernate; do
    echo "logind $a: $(busctl call org.freedesktop.login1 /org/freedesktop/login1 org.freedesktop.login1.Manager $a 2>/dev/null | awk '{print $2}')"
  done
  systemd-analyze cat-config systemd/sleep.conf 2>/dev/null | grep -E '^(HibernateDelaySec|HibernateOnACPower|HibernateMode)' | sed 's/^/  sleep.conf: /'
  systemd-analyze cat-config systemd/logind.conf 2>/dev/null | grep -E '^HandleLidSwitch' | sed 's/^/  logind.conf: /'
  [ -f $UNLOAD ] && echo "unload before hibernate: $(cat $UNLOAD)"
  return 0
}

# Physical offset of a swap file's first extent, in pages (what resume_offset= expects).
swap_offset() {
  if [ "$(findmnt -no FSTYPE -T "$1")" = btrfs ]; then btrfs inspect-internal map-swapfile -r "$1"
  else filefrag -v "$1" | awk '$1=="0:"{print $4}' | tr -d .; fi
}

regen_initramfs() {
  if command -v update-initramfs >/dev/null; then update-initramfs -u -k all
  elif command -v dracut >/dev/null; then dracut -f --regenerate-all
  elif command -v mkinitcpio >/dev/null; then echo "mkinitcpio: add 'resume' to HOOKS in /etc/mkinitcpio.conf (after udev), then: mkinitcpio -P"
  else echo "Unknown initramfs tool: make sure it includes resume support"; fi
}

regen_grub() {
  if command -v update-grub >/dev/null; then update-grub
  elif command -v grub2-mkconfig >/dev/null; then grub2-mkconfig -o /boot/grub2/grub.cfg
  elif command -v grub-mkconfig >/dev/null; then grub-mkconfig -o /boot/grub/grub.cfg
  else echo "No GRUB found: add $* to your bootloader's kernel command line"; return 1; fi
}

while [ $# -gt 0 ]; do case "$1" in
  --status) status ;;

  --setup)
    ram=$(awk '/MemTotal/{print $2*1024}' /proc/meminfo)
    swap=$(swapon --show=NAME,TYPE,SIZE --bytes --noheadings | sort -k3 -n | tail -1)
    [ -n "$swap" ] || { echo "No active swap. Create a swap file or partition at least as big as RAM first."; exit 1; }
    read -r dev type size <<<"$swap"
    if [ "$type" = file ]; then
      if [ "$size" -lt "$ram" ]; then
        # Grow the swap file to RAM rounded up to whole GiB (+1). Needs its contents to fit back in RAM.
        want=$(( ram / 1073741824 + 1 ))G
        used=$(swapon --show=USED --bytes --noheadings "$dev" | tr -d ' ')
        avail=$(awk '/MemAvailable/{print $2*1024}' /proc/meminfo)
        [ "${used:-0}" -lt "$avail" ] || { echo "Not enough free RAM to empty swap; close some apps"; exit 1; }
        [ "$(findmnt -no FSTYPE -T "$dev")" != btrfs ] || { echo "btrfs: recreate the swap file with 'btrfs filesystem mkswapfile --size $want $dev'"; exit 1; }
        echo "Growing $dev to $want"
        swapoff "$dev"; rm -f "$dev"; fallocate -l "$want" "$dev"; chmod 600 "$dev"; mkswap "$dev"; swapon "$dev"
      fi
      uuid=$(findmnt -no UUID -T "$dev"); offset=$(swap_offset "$dev")
      [[ "$offset" =~ ^[0-9]+$ ]] || { echo "Could not read the swap file offset"; exit 1; }
      params="resume=UUID=$uuid resume_offset=$offset"
    else
      [ "$size" -ge "$ram" ] || echo "WARNING: swap partition is smaller than RAM; hibernation can fail when memory is full"
      params="resume=UUID=$(blkid -s UUID -o value "$dev")"
    fi
    echo "Kernel parameters: $params"
    mkdir -p /etc/default/grub.d
    printf '# macbook-sleep: hibernation resume location. Re-run hibernate.sh --setup if the swap file is recreated.\nGRUB_CMDLINE_LINUX_DEFAULT="$GRUB_CMDLINE_LINUX_DEFAULT %s"\n' "$params" \
      > /etc/default/grub.d/91-macbook-resume.cfg
    if command -v dracut >/dev/null; then
      mkdir -p /etc/dracut.conf.d; echo 'add_dracutmodules+=" resume "' > /etc/dracut.conf.d/90-macbook-resume.conf
    fi
    if [ -d /etc/initramfs-tools/conf.d ] && ! command -v dracut >/dev/null; then
      echo "RESUME=${params#resume=}" | cut -d' ' -f1 > /etc/initramfs-tools/conf.d/90-macbook-resume
    fi
    regen_grub "$params"; regen_initramfs
    echo "Done: reboot, then run --status (the kernel resume device should no longer be 0:0)" ;;

  --allow)
    # Ubuntu's com.ubuntu.desktop.rules returns NO for hibernation. Rules in /etc are read first.
    mkdir -p /etc/polkit-1/rules.d
    cat > /etc/polkit-1/rules.d/10-macbook-allow-hibernate.rules <<'R'
// macbook-sleep: allow hibernation (and suspend-then-hibernate) for the active local user.
// Overrides Ubuntu's "Disable hibernate by default" rule in com.ubuntu.desktop.rules.
polkit.addRule(function(action, subject) {
    if ((action.id == "org.freedesktop.login1.hibernate" ||
         action.id == "org.freedesktop.login1.handle-hibernate-key" ||
         action.id == "org.freedesktop.login1.hibernate-multiple-sessions" ||
         action.id == "org.freedesktop.upower.hibernate") &&
        subject.active && subject.local) {
            return polkit.Result.YES;
    }
});
R
    sleep 2; status | grep '^logind' ;;

  --unload)
    mkdir -p /etc/macbook-sleep; echo "$2" > $UNLOAD; shift
    cat > $HOOK <<'H'
#!/bin/sh
# macbook-sleep: unload modules that break hibernation (listed in /etc/macbook-sleep/hibernate-unload).
# $1 = pre|post. During suspend-then-hibernate, SYSTEMD_SLEEP_ACTION is the current step.
[ -f /etc/macbook-sleep/hibernate-unload ] || exit 0
action="${SYSTEMD_SLEEP_ACTION:-$2}"
case "$1/$action" in
    pre/hibernate|pre/hybrid-sleep) modprobe -r $(cat /etc/macbook-sleep/hibernate-unload) ;;
    post/*) for m in $(cat /etc/macbook-sleep/hibernate-unload); do modprobe "$m"; done ;;
esac
exit 0
H
    chmod 755 $HOOK; echo "Hook installed: $HOOK, unloads: $(cat $UNLOAD)" ;;

  --test)
    # Writes the image and restores it right away, without powering off. Kernel logs survive, unlike a real
    # hibernation, so this is the way to see why one fails. Bypasses systemd, so do the hook's unload here.
    [ -f $UNLOAD ] && modprobe -r $(cat $UNLOAD)
    old=$(grep -o '\[[a-z_]*\]' /sys/power/disk | tr -d '[]')
    echo 1 > /sys/power/pm_debug_messages; dmesg -C
    echo test_resume > /sys/power/disk; sync
    rc=0; echo disk > /sys/power/state || rc=$?
    echo "$old" > /sys/power/disk; echo 0 > /sys/power/pm_debug_messages
    [ -f $UNLOAD ] && for m in $(cat $UNLOAD); do modprobe "$m"; done
    dmesg | grep -E 'PM:|hibernat|abort|fail|error|Timeout' | grep -vE 'Marking nosave|progress' | tail -40
    if dmesg | grep -q 'Hibernation image restored successfully'; then echo "RESULT: OK (write rc=$rc)"
    else echo "RESULT: FAILED (write rc=$rc). Look for the device that aborted 'freeze' or 'quiesce' above"; fi ;;

  --lid)
    delay="$2"; shift
    [[ "$delay" =~ ^[0-9]+(s|min|h)$ ]] || { echo "Delay must look like 90s, 10min or 1h"; exit 1; }
    mkdir -p /etc/systemd/sleep.conf.d /etc/systemd/logind.conf.d
    printf '# macbook-sleep: sleep first, hibernate after this delay (s2idle drains the battery).\n[Sleep]\nHibernateDelaySec=%s\n# On the charger, keep sleeping instead of hibernating.\nHibernateOnACPower=no\n' "$delay" \
      > /etc/systemd/sleep.conf.d/90-macbook-hibernate.conf
    printf '# macbook-sleep: lid on battery = sleep, then hibernate; on the charger = sleep.\n[Login]\nHandleLidSwitch=suspend-then-hibernate\nHandleLidSwitchExternalPower=suspend\n' \
      > /etc/systemd/logind.conf.d/90-macbook-lid.conf
    status | grep -E 'sleep.conf|logind.conf|SuspendThen'
    echo "Delay changes apply at the next lid close. After the first --lid, reboot so logind reads the lid setting." ;;

  --grub-no-wait)
    # Ubuntu GRUB sets recordfail at boot; a hibernation never clears it, so the next start waits 30 s on a hidden menu.
    mkdir -p /etc/default/grub.d
    printf '# macbook-sleep: after hibernation, recordfail is left set; do not wait 30 s on the boot menu.\nGRUB_RECORDFAIL_TIMEOUT=0\n' \
      > /etc/default/grub.d/92-macbook-no-recordfail-wait.cfg
    regen_grub ;;

  *) echo "unknown option: $1"; exit 1 ;;
esac; shift; done
