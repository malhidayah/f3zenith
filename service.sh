#!/system/bin/sh
# F3Zenith - apply the saved profile on boot.
export PATH=/system/xbin:/system/bin:/system/sbin:$PATH

CFG=""
for p in /data/local/tmp/f3zenith/profile /data/adb/f3zenith/profile; do
  [ -f "$p" ] && { CFG="$p"; break; }
done
[ -n "$CFG" ] || exit 0
p=$(cat "$CFG" 2>/dev/null)
[ -n "$p" ] || exit 0

# MT6750 exposes two cpufreq policies: little cpu0-3, big cpu4-7. The big
# cluster parks itself when idle and its node disappears with it, so every
# write is guarded by a -f test instead of spraying errors at boot.
i=0
while [ ! -f /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor ] && [ "$i" -lt 30 ]; do
  sleep 1; i=$((i+1))
done
[ -f /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor ] || exit 0

setgov() {
  for c in /sys/devices/system/cpu/cpu[0-9]*; do
    f="$c/cpufreq/scaling_governor"
    [ -f "$f" ] && echo "$1" > "$f" 2>/dev/null
  done
}
setmax() { # little_pct big_pct
  # write the rounded value DOWN to a step the driver actually accepts;
  # mt_cpufreq silently rejects anything not in its table (it keeps, not
  # clamps, the old value -- hence "still 1001000").
  tbl0=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_frequencies 2>/dev/null)
  tbl4=$(cat /sys/devices/system/cpu/cpu4/cpufreq/scaling_available_frequencies 2>/dev/null)
  [ -n "$tbl4" ] || tbl4="$tbl0"
  [ -n "$tbl0" ] || { tbl0="1001000"; tbl4="1508000"; }
  hi0=${tbl0%% *}; hi4=${tbl4%% *}
  lim0=$((hi0 * $1 / 100)); lim4=$((hi4 * $2 / 100))
  for t in $tbl0; do [ "$t" -le "$lim0" ] && { lim0=$t; break; }; done
  for t in $tbl4; do [ "$t" -le "$lim4" ] && { lim4=$t; break; }; done
  for c in /sys/devices/system/cpu/cpu[0-9]*; do
    f="$c/cpufreq/scaling_max_freq"
    [ -f "$f" ] || continue
    n=${c##*/}; n=${n#cpu}
    if [ "$n" -lt 4 ]; then echo "$lim0" > "$f" 2>/dev/null
    else                   echo "$lim4" > "$f" 2>/dev/null; fi
  done
}
setsched() { echo "$1" > /sys/block/mmcblk0/queue/scheduler 2>/dev/null; }

case "$p" in
  performance) setgov performance; setmax 100 100; setsched noop ;;
  balanced)    setgov interactive; setmax 80 80;   setsched cfq ;;
  eco)         setgov powersave;   setmax 50 50;   setsched deadline ;;
esac
