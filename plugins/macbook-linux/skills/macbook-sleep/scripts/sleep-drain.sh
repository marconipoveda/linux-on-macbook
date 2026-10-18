#!/bin/bash
# Measure battery used while asleep (normal user, on battery).
#   bash sleep-drain.sh start   # right before closing the lid
#   bash sleep-drain.sh stop    # right after waking
F="${XDG_STATE_HOME:-$HOME/.local/state}/macbook-sleep-drain"; mkdir -p "$(dirname "$F")"
B=$(upower -e | grep -m1 battery_)
val() { upower -i "$B" | awk -v k="$1" '$1==k":"{print $2}'; }
E=$(val energy); P=$(val percentage); FULL=$(val energy-full)
case "$1" in
  start) echo "$(date +%s) $E $P" > "$F"; echo "start: $E Wh ($P) at $(date +%T)" ;;
  stop)  read -r t0 e0 p0 < "$F"
         awk -v e0="$e0" -v e1="$E" -v s="$(( $(date +%s) - t0 ))" -v p0="$p0" -v p1="$P" -v full="$FULL" 'BEGIN{
             h=s/3600; d=e0-e1; printf "slept %.1f h, %s -> %s, used %.2f Wh = %.2f W = %.1f %%/h\n", h, p0, p1, d, d/h, 100*d/h/full}' ;;
  *) echo "usage: $0 start|stop" ;;
esac
