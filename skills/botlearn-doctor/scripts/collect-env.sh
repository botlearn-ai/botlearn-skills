#!/bin/bash
# collect-env.sh — Collect environment information, output JSON
# Timeout: 10s | Compatible: macOS (darwin) + Linux
set -euo pipefail

get_os() {
  local os_name
  os_name="$(uname -s)"
  local os_ver
  os_ver="$(uname -r)"
  echo "${os_name} ${os_ver}"
}

get_arch() {
  uname -m
}

get_node_version() {
  node --version 2>/dev/null || echo "NOT_FOUND"
}

get_pnpm_version() {
  pnpm --version 2>/dev/null || echo "NOT_FOUND"
}

get_npm_version() {
  npm --version 2>/dev/null || echo "NOT_FOUND"
}

get_openclaw_version() {
  openclaw --version 2>/dev/null || echo "NOT_FOUND"
}

get_clawhub_version() {
  clawhub --version 2>/dev/null || echo "NOT_FOUND"
}

get_memory_total_mb() {
  if [[ "$(uname -s)" == "Darwin" ]]; then
    sysctl -n hw.memsize 2>/dev/null | awk '{printf "%d", $1/1048576}'
  else
    free -m 2>/dev/null | awk '/Mem:/{print $2}'
  fi
}

get_memory_available_mb() {
  if [[ "$(uname -s)" == "Darwin" ]]; then
    local page_size
    page_size=$(sysctl -n hw.pagesize 2>/dev/null || echo 4096)
    local free_pages
    free_pages=$(vm_stat 2>/dev/null | awk '/Pages free/{gsub(/\./,""); print $3}')
    local inactive_pages
    inactive_pages=$(vm_stat 2>/dev/null | awk '/Pages inactive/{gsub(/\./,""); print $3}')
    echo $(( (free_pages + inactive_pages) * page_size / 1048576 ))
  else
    free -m 2>/dev/null | awk '/Mem:/{print $7}'
  fi
}

get_disk_total_gb() {
  if [[ "$(uname -s)" == "Darwin" ]]; then
    df -g / 2>/dev/null | awk 'NR==2{print $2}'
  else
    df -BG / 2>/dev/null | awk 'NR==2{print $2+0}'
  fi
}

get_disk_available_gb() {
  if [[ "$(uname -s)" == "Darwin" ]]; then
    df -g / 2>/dev/null | awk 'NR==2{print $4}'
  else
    df -BG / 2>/dev/null | awk 'NR==2{print $4+0}'
  fi
}

get_cpu_cores() {
  if [[ "$(uname -s)" == "Darwin" ]]; then
    sysctl -n hw.ncpu 2>/dev/null || echo 0
  else
    nproc 2>/dev/null || echo 0
  fi
}

get_cpu_load() {
  if [[ "$(uname -s)" == "Darwin" ]]; then
    sysctl -n vm.loadavg 2>/dev/null | awk '{print $2}'
  else
    awk '{print $1}' /proc/loadavg 2>/dev/null || echo "0"
  fi
}

get_uptime_hours() {
  if [[ "$(uname -s)" == "Darwin" ]]; then
    local boot_time
    boot_time=$(sysctl -n kern.boottime 2>/dev/null | awk '{print $4}' | tr -d ',')
    local now
    now=$(date +%s)
    echo $(( (now - boot_time) / 3600 ))
  else
    awk '{printf "%d", $1/3600}' /proc/uptime 2>/dev/null || echo 0
  fi
}

# Output JSON
cat <<EOF
{
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "os": "$(get_os)",
  "arch": "$(get_arch)",
  "node_version": "$(get_node_version)",
  "npm_version": "$(get_npm_version)",
  "pnpm_version": "$(get_pnpm_version)",
  "openclaw_version": "$(get_openclaw_version)",
  "clawhub_version": "$(get_clawhub_version)",
  "memory": {
    "total_mb": $(get_memory_total_mb),
    "available_mb": $(get_memory_available_mb)
  },
  "disk": {
    "total_gb": $(get_disk_total_gb),
    "available_gb": $(get_disk_available_gb)
  },
  "cpu": {
    "cores": $(get_cpu_cores),
    "load_avg_1m": $(get_cpu_load)
  },
  "uptime_hours": $(get_uptime_hours)
}
EOF
