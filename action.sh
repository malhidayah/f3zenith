#!/system/bin/sh
# F3Zenith status for the Magisk action button. Same live values
# the WebUI reads from /sys, so Magisk and WebUI never disagree.
export PATH=/system/xbin:/system/bin:/system/sbin:$PATH
gov=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null)
gov4=$(cat /sys/devices/system/cpu/cpu4/cpufreq/scaling_governor 2>/dev/null)
[ -z "$gov4" ] && gov4="$gov"
sched=$(cat /sys/block/mmcblk0/queue/scheduler 2>/dev/null | sed -n 's/.*\[\([^]]*\)\].*/\1/p')
max0=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq 2>/dev/null)
max4=$(cat /sys/devices/system/cpu/cpu4/cpufreq/scaling_max_freq 2>/dev/null)
tcpu=$(cat /sys/class/thermal/thermal_zone1/temp 2>/dev/null)
tbat=$(cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null)
echo "F3Zenith"
echo "governor  : $gov / $gov4"
echo "scheduler : ${sched:-?}"
echo "freq max  : ${max0:-?} / ${max4:-?}"
echo "temp cpu  : ${tcpu:-?}  bat: ${tbat:-?}  (raw millidegrees)"
[ -n "$tcpu" ] && [ -n "$tbat" ] && echo "          = $((tcpu/1000))C / $((tbat/1000))C"
echo "profiles  : performance / balanced / eco  (via WebUI)"
