#!/usr/bin/env bash
# collect-dissatisfaction.sh — 测阶段：挖掘不满意点
# Queries Memory API for low-satisfaction sessions, parses error logs,
# detects negative feedback, and scores each dissatisfaction candidate.
# Output: JSON with candidates array to stdout
set -euo pipefail

# --- Configuration ---
OPENCLAW_HOME="${OPENCLAW_HOME:-$HOME/.openclaw}"
OPENCLAW_GATEWAY="${OPENCLAW_GATEWAY:-http://localhost:3000}"
DATA_DIR="$OPENCLAW_HOME/data/self-learn"
TIMEOUT=10
SATISFACTION_THRESHOLD="${SATISFACTION_THRESHOLD:-0.6}"
MAX_CANDIDATES="${MAX_CANDIDATES:-20}"

# --- Scoring weights (from scoring-model.json) ---
W_RECENCY=0.3
W_FREQUENCY=0.3
W_SEVERITY=0.4
DECAY_HALF_LIFE_HOURS=168

# --- Helper: timestamp ---
now_iso() { date -u +"%Y-%m-%dT%H:%M:%SZ"; }
now_epoch() { date +%s; }

# --- Helper: safe curl with timeout ---
api_get() {
  local url="$1"
  curl -sf --max-time "$TIMEOUT" -H "Content-Type: application/json" "$url" 2>/dev/null || echo '{"error":"request_failed"}'
}

# --- Step 1: Query Memory API for low-satisfaction sessions ---
collect_low_satisfaction() {
  local result
  result=$(api_get "$OPENCLAW_GATEWAY/memory/sessions?satisfaction_lt=$SATISFACTION_THRESHOLD&limit=50&sort=timestamp:desc")

  if echo "$result" | jq -e '.error' >/dev/null 2>&1; then
    echo '[]'
    return
  fi

  echo "$result" | jq -c '[.sessions // [] | .[] | {
    task_id: .task_id,
    session_id: .session_id,
    original_request: .request,
    satisfaction: .satisfaction,
    timestamp: .timestamp,
    failure_type: "low_satisfaction",
    error_message: null
  }]' 2>/dev/null || echo '[]'
}

# --- Step 2: Parse error/failure patterns from logs ---
collect_error_patterns() {
  local log_dir="$OPENCLAW_HOME/logs"
  if [ ! -d "$log_dir" ]; then
    echo '[]'
    return
  fi

  # Search recent logs (last 7 days) for ERROR/FAILED patterns
  local candidates='[]'
  local cutoff_epoch
  cutoff_epoch=$(( $(now_epoch) - 604800 ))

  for log_file in "$log_dir"/*.log "$log_dir"/*.json; do
    [ -f "$log_file" ] || continue

    # Skip files older than 7 days
    local file_epoch
    if [[ "$OSTYPE" == "darwin"* ]]; then
      file_epoch=$(stat -f %m "$log_file" 2>/dev/null || echo 0)
    else
      file_epoch=$(stat -c %Y "$log_file" 2>/dev/null || echo 0)
    fi
    [ "$file_epoch" -lt "$cutoff_epoch" ] && continue

    # Extract error entries
    local errors
    errors=$(grep -iE '(ERROR|FAILED|EXCEPTION|CRASH|TIMEOUT)' "$log_file" 2>/dev/null | tail -20 || true)

    if [ -n "$errors" ]; then
      # Parse structured log entries if JSON format
      if echo "$errors" | head -1 | jq -e '.' >/dev/null 2>&1; then
        local parsed
        parsed=$(echo "$errors" | jq -sc '[.[] | select(.task_id != null) | {
          task_id: .task_id,
          session_id: (.session_id // "unknown"),
          original_request: (.request // .message // "Error in task"),
          satisfaction: 0.0,
          timestamp: (.timestamp // "'$(now_iso)'"),
          failure_type: "error",
          error_message: (.error // .message // "unknown error")
        }]' 2>/dev/null || echo '[]')
        candidates=$(echo "$candidates" "$parsed" | jq -s 'add' 2>/dev/null || echo "$candidates")
      fi
    fi
  done

  echo "$candidates"
}

# --- Step 3: Detect explicit negative feedback ---
collect_negative_feedback() {
  local result
  result=$(api_get "$OPENCLAW_GATEWAY/memory/feedback?sentiment=negative&limit=30&sort=timestamp:desc")

  if echo "$result" | jq -e '.error' >/dev/null 2>&1; then
    echo '[]'
    return
  fi

  echo "$result" | jq -c '[.feedback // [] | .[] | {
    task_id: .task_id,
    session_id: .session_id,
    original_request: (.original_request // .context // "Negative feedback"),
    satisfaction: 0.1,
    timestamp: .timestamp,
    failure_type: "explicit_negative",
    error_message: .feedback_text
  }]' 2>/dev/null || echo '[]'
}

# --- Step 4: Calculate dissatisfaction_score for each candidate ---
calculate_scores() {
  local candidates="$1"
  local current_epoch
  current_epoch=$(now_epoch)

  echo "$candidates" | jq -c --argjson now "$current_epoch" \
    --argjson wr "$W_RECENCY" --argjson wf "$W_FREQUENCY" --argjson ws "$W_SEVERITY" \
    --argjson half_life "$DECAY_HALF_LIFE_HOURS" '
    # Group by task_id to count frequency
    group_by(.task_id) |
    map(
      . as $group |
      ($group | length) as $freq |
      $group[0] + {
        frequency: $freq,
        dissatisfaction_score: (
          # Recency: exponential decay
          (
            (($group[0].timestamp // "" | if . == "" then 0 else (($now - (. | split("T") | .[0] | split("-") | map(tonumber) |
              if length == 3 then (.[0]-1970)*31536000 + (.[1]-1)*2592000 + (.[2]-1)*86400 else 0 end)) / 3600) end)
            ) as $hours_since |
            ((-0.693 * $hours_since / $half_life) | exp) * $wr
          ) +
          # Frequency
          ([1.0, ($freq / 5)] | min) * $wf +
          # Severity
          (
            if .failure_type == "error" then 1.0
            elif .failure_type == "explicit_negative" then 0.9
            elif .failure_type == "incomplete" then 0.7
            elif .failure_type == "low_satisfaction" then 0.5
            elif .failure_type == "timeout" then 0.4
            else 0.3 end
          ) * $ws
        )
      }
    ) |
    sort_by(-.dissatisfaction_score) |
    .[:'"$MAX_CANDIDATES"']
  ' 2>/dev/null || echo "$candidates"
}

# --- Step 5: Deduplicate (exclude tasks already in active learning) ---
deduplicate() {
  local candidates="$1"
  local registry="$DATA_DIR/tasks/registry.json"

  if [ ! -f "$registry" ]; then
    echo "$candidates"
    return
  fi

  # Get task IDs that are already in_progress
  local active_ids
  active_ids=$(jq -r '[.tasks // {} | to_entries[] | select(.value.status == "in_progress") | .key] | join("|")' "$registry" 2>/dev/null || echo "")

  if [ -z "$active_ids" ]; then
    echo "$candidates"
    return
  fi

  echo "$candidates" | jq -c --arg active "$active_ids" '
    [.[] | select(.task_id | test($active) | not)]
  ' 2>/dev/null || echo "$candidates"
}

# --- Parse mode flags ---
MODE="default"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --heartbeat)
      # Heartbeat mode: lightweight check, exit 0 if candidates found (healthy signal)
      # Used by: clawhub health register --check-script
      MODE="heartbeat"
      shift ;;
    --auto)
      # Auto mode: run full pipeline, triggered by cron/scheduler
      # Used by: clawhub cron / system crontab
      MODE="auto"
      shift ;;
    *) shift ;;
  esac
done

# --- Main ---
main() {
  local started_at
  started_at=$(now_iso)

  # Collect from all sources in parallel
  local low_sat errors feedback
  low_sat=$(collect_low_satisfaction)
  errors=$(collect_error_patterns)
  feedback=$(collect_negative_feedback)

  # Merge all candidates
  local merged
  merged=$(echo "$low_sat" "$errors" "$feedback" | jq -s 'add | unique_by(.task_id)' 2>/dev/null || echo '[]')

  # Score candidates
  local scored
  scored=$(calculate_scores "$merged")

  # Deduplicate
  local final
  final=$(deduplicate "$scored")

  local count
  count=$(echo "$final" | jq 'length' 2>/dev/null || echo 0)

  # --- Heartbeat mode: return health status for Gateway ---
  if [ "$MODE" = "heartbeat" ]; then
    # Gateway expects: exit 0 = healthy (candidates found, learning needed)
    #                  exit 1 = no action needed
    if [ "$count" -gt 0 ]; then
      jq -n --argjson count "$count" '{ status: "learning_needed", candidates: $count }'
      exit 0
    else
      jq -n '{ status: "clean", candidates: 0 }'
      exit 0
    fi
  fi

  # --- Auto mode: output + trigger full cycle via Gateway ---
  if [ "$MODE" = "auto" ]; then
    if [ "$count" -gt 0 ]; then
      # Write candidates to temp file for pipeline consumption
      local tmp_file="/tmp/self-learn-candidates-$(date +%s).json"
      jq -n \
        --arg started_at "$started_at" \
        --arg completed_at "$(now_iso)" \
        --argjson candidates "$final" \
        --argjson count "$count" \
        --arg threshold "$SATISFACTION_THRESHOLD" \
        '{
          version: "2.0.0",
          phase: "test",
          trigger: "auto",
          started_at: $started_at,
          completed_at: $completed_at,
          satisfaction_threshold: ($threshold | tonumber),
          candidates_found: $count,
          candidates: $candidates
        }' > "$tmp_file"
      echo "$tmp_file"
    else
      echo "no_candidates"
    fi
    exit 0
  fi

  # --- Default mode: full JSON output to stdout ---
  jq -n \
    --arg started_at "$started_at" \
    --arg completed_at "$(now_iso)" \
    --argjson candidates "$final" \
    --argjson count "$count" \
    --arg threshold "$SATISFACTION_THRESHOLD" \
    '{
      version: "2.0.0",
      phase: "test",
      started_at: $started_at,
      completed_at: $completed_at,
      satisfaction_threshold: ($threshold | tonumber),
      candidates_found: $count,
      candidates: $candidates
    }'
}

main
