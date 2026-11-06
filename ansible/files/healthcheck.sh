#!/usr/bin/env bash
# healthcheck.sh - Checks disk, memory, load and services
# Exit codes: 0=OK, 1=WARN, 2=CRIT
set -uo pipefail

DISK_THRESHOLD="${DISK_THRESHOLD:-85}"
MEM_MIN_PCT="${MEM_MIN_PCT:-10}"
SERVICES=(${SERVICES:-sshd})
status=0

raise() { (( $1 > status )) && status=$1; }

echo "=== Healthcheck $(hostname) - $(date '+%F %T') ==="

# Disk usage
while read -r usage mount; do
  pct="${usage%\%}"
  if (( pct >= DISK_THRESHOLD )); then
    echo "CRIT disk: ${mount} at ${usage}"
    raise 2
  fi
done < <(df -x tmpfs -x devtmpfs --output=pcent,target | tail -n +2)

# Available memory
mem_avail=$(awk '/MemTotal/ {t=$2} /MemAvailable/ {a=$2} END {printf "%d", a*100/t}' /proc/meminfo)
if (( mem_avail < MEM_MIN_PCT )); then
  echo "WARN memory: only ${mem_avail}% available"
  raise 1
fi

# Load average vs CPU count
read -r load1 _ < /proc/loadavg
cpus=$(nproc)
if awk -v l="$load1" -v c="$cpus" 'BEGIN {exit !(l > c)}'; then
  echo "WARN load: ${load1} with ${cpus} CPUs"
  raise 1
fi

# Services
for svc in "${SERVICES[@]}"; do
  if ! systemctl is-active --quiet "$svc"; then
    echo "CRIT service: ${svc} is not active"
    raise 2
  fi
done

(( status == 0 )) && echo "OK: disk<${DISK_THRESHOLD}%, memory ${mem_avail}% free, load ${load1}/${cpus} CPUs"
exit "$status"
