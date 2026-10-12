#!/system/bin/sh
# MT6750 has two policies: little (cpu0-3) and big (cpu4-7).
# Writing policy files only covers the part of the policy that is online,
# so also write the offline nodes explicitly before the write disappears.
export PATH=/system/xbin:/system/bin:/system/sbin:$PATH
g="$1"; [ -n "$g" ] || { echo "usage: setgov.sh <governor>"; exit 1; }
avail=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_governors 2>/dev/null)
case " $avail " in
  *" $g "*) ;;
  *) echo "error: governor not available: $g"; exit 1 ;;
esac
for c in 0 1 2 3 4 5 6 7; do
  f=/sys/devices/system/cpu/cpu$c/cpufreq/scaling_governor
  [ -f "$f" ] && echo "$g" > "$f" 2>/dev/null
done
for c in 0 4; do
  f=/sys/devices/system/cpu/cpufreq/$c/scaling_governor
  [ -f "$f" ] && echo "$g" > "$f" 2>/dev/null
done
# hotplug dir too, in case the driver mirrors values there
for c in 0 1 2 3 4 5 6 7; do
  f=/sys/devices/system/cpu/cpu$c/cpufreq/$c/scaling_governor
  [ -f "$f" ] && echo "$g" > "$f" 2>/dev/null
done
echo "gov=$g"
