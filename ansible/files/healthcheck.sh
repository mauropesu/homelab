#!/usr/bin/env bash
# healthcheck.sh - Revisa disco, memoria, carga y servicios
# Exit codes: 0=OK, 1=WARN, 2=CRIT
set -uo pipefail

DISK_THRESHOLD="${DISK_THRESHOLD:-85}"
MEM_MIN_PCT="${MEM_MIN_PCT:-10}"
SERVICES=(${SERVICES:-sshd})
status=0

raise() { (( $1 > status )) && status=$1; }

echo "=== Healthcheck $(hostname) - $(date '+%F %T') ==="

# Disco
while read -r usage mount; do
  pct="${usage%\%}"
  if (( pct >= DISK_THRESHOLD )); then
    echo "CRIT disco: ${mount} al ${usage}"
    raise 2
  fi
done < <(df -x tmpfs -x devtmpfs --output=pcent,target | tail -n +2)

# Memoria disponible
mem_avail=$(awk '/MemTotal/ {t=$2} /MemAvailable/ {a=$2} END {printf "%d", a*100/t}' /proc/meminfo)
if (( mem_avail < MEM_MIN_PCT )); then
  echo "WARN memoria: solo ${mem_avail}% disponible"
  raise 1
fi

# Carga vs numero de CPUs
read -r load1 _ < /proc/loadavg
cpus=$(nproc)
if awk -v l="$load1" -v c="$cpus" 'BEGIN {exit !(l > c)}'; then
  echo "WARN carga: ${load1} con ${cpus} CPUs"
  raise 1
fi

# Servicios
for svc in "${SERVICES[@]}"; do
  if ! systemctl is-active --quiet "$svc"; then
    echo "CRIT servicio: ${svc} no esta activo"
    raise 2
  fi
done

(( status == 0 )) && echo "OK: disco<${DISK_THRESHOLD}%, memoria ${mem_avail}% libre, carga ${load1}/${cpus} CPUs"
exit "$status"
