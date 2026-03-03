#!/bin/bash
# collect-journey.sh — Collect 7-day journey data: start date, installed skills, workspace files, Day 1 baseline
# Timeout: 15s | Compatible: macOS (darwin) + Linux
# Output: JSON to stdout
set -euo pipefail

OPENCLAW_HOME="${OPENCLAW_HOME:-$HOME/.openclaw}"
GRADUATE_DATA="${OPENCLAW_HOME}/data/graduate"

# --- Helper functions ---

get_journey_start() {
  local start_file="${GRADUATE_DATA}/journey-start.json"
  if [[ -f "$start_file" ]]; then
    cat "$start_file" 2>/dev/null | jq -r '.startDate // empty' 2>/dev/null || echo ""
  else
    echo ""
  fi
}

get_current_day() {
  local start_date
  start_date="$(get_journey_start)"
  if [[ -z "$start_date" ]]; then
    echo 0
    return
  fi
  local start_epoch now_epoch
  if [[ "$(uname -s)" == "Darwin" ]]; then
    start_epoch=$(date -j -f "%Y-%m-%d" "$start_date" "+%s" 2>/dev/null || echo 0)
  else
    start_epoch=$(date -d "$start_date" "+%s" 2>/dev/null || echo 0)
  fi
  now_epoch=$(date "+%s")
  if [[ "$start_epoch" -eq 0 ]]; then
    echo 0
    return
  fi
  local diff_days=$(( (now_epoch - start_epoch) / 86400 + 1 ))
  # Clamp to 1-7
  if [[ "$diff_days" -lt 1 ]]; then diff_days=1; fi
  if [[ "$diff_days" -gt 7 ]]; then diff_days=7; fi
  echo "$diff_days"
}

get_installed_skills() {
  local skills_dir="${OPENCLAW_HOME}/skills"
  if [[ -d "$skills_dir" ]]; then
    local count=0
    local skill_list="[]"
    local items=()
    for manifest in "$skills_dir"/*/manifest.json; do
      if [[ -f "$manifest" ]]; then
        local name
        name=$(jq -r '.name // "unknown"' "$manifest" 2>/dev/null || echo "unknown")
        local version
        version=$(jq -r '.version // "0.0.0"' "$manifest" 2>/dev/null || echo "0.0.0")
        items+=("{\"name\":\"$name\",\"version\":\"$version\"}")
        count=$((count + 1))
      fi
    done
    if [[ ${#items[@]} -gt 0 ]]; then
      local joined
      joined=$(printf ",%s" "${items[@]}")
      joined="${joined:1}"
      echo "{\"count\":$count,\"skills\":[$joined]}"
    else
      echo "{\"count\":0,\"skills\":[]}"
    fi
  else
    echo "{\"count\":0,\"skills\":[]}"
  fi
}

check_workspace_file() {
  local file_name="$1"
  # Check common locations
  for dir in "." "$OPENCLAW_HOME" "$OPENCLAW_HOME/workspace"; do
    if [[ -f "$dir/$file_name" ]]; then
      local lines
      lines=$(wc -l < "$dir/$file_name" 2>/dev/null | tr -d ' ')
      local size
      size=$(wc -c < "$dir/$file_name" 2>/dev/null | tr -d ' ')
      echo "{\"exists\":true,\"path\":\"$dir/$file_name\",\"lines\":$lines,\"bytes\":$size}"
      return
    fi
  done
  echo "{\"exists\":false,\"path\":null,\"lines\":0,\"bytes\":0}"
}

get_baseline() {
  local baseline_file="${GRADUATE_DATA}/day1-baseline.json"
  if [[ -f "$baseline_file" ]]; then
    cat "$baseline_file" 2>/dev/null || echo "{}"
  else
    echo "{}"
  fi
}

get_session_count() {
  local log_dir="${OPENCLAW_HOME}/logs"
  if [[ -d "$log_dir" ]]; then
    find "$log_dir" -name "*.log" -o -name "*.jsonl" 2>/dev/null | wc -l | tr -d ' '
  else
    echo "0"
  fi
}

# --- Output JSON ---

SKILLS_JSON=$(get_installed_skills)
SOUL_JSON=$(check_workspace_file "SOUL.md")
USER_JSON=$(check_workspace_file "USER.md")
AGENTS_JSON=$(check_workspace_file "AGENTS.md")
BASELINE_JSON=$(get_baseline)
JOURNEY_START=$(get_journey_start)
CURRENT_DAY=$(get_current_day)
SESSION_COUNT=$(get_session_count)

cat <<EOF
{
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "journey": {
    "startDate": "${JOURNEY_START:-null}",
    "currentDay": $CURRENT_DAY,
    "endDate": "$(date -u +%Y-%m-%d)"
  },
  "skills": $SKILLS_JSON,
  "workspace": {
    "soulMd": $SOUL_JSON,
    "userMd": $USER_JSON,
    "agentsMd": $AGENTS_JSON
  },
  "sessions": {
    "estimatedCount": $SESSION_COUNT
  },
  "baseline": $BASELINE_JSON
}
EOF
