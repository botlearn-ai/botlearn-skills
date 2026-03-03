#!/usr/bin/env bash
# record-cycle.sh — 评阶段：持久化循环数据
# Reads a complete cycle record from stdin, validates against schema,
# writes to cycles/ directory (append-only), updates task registry,
# extracts learning patterns, and updates the latest snapshot.
# Output: JSON with cycle_id, stored_at, patterns_extracted to stdout
set -euo pipefail

# --- Configuration ---
OPENCLAW_HOME="${OPENCLAW_HOME:-$HOME/.openclaw}"
DATA_DIR="$OPENCLAW_HOME/data/self-learn"
CYCLES_DIR="$DATA_DIR/cycles"
TASKS_DIR="$DATA_DIR/tasks"
PATTERNS_DIR="$DATA_DIR/patterns"
SNAPSHOTS_DIR="$DATA_DIR/snapshots"

# --- Helper ---
now_iso() { date -u +"%Y-%m-%dT%H:%M:%SZ"; }

# --- Read cycle record from stdin ---
CYCLE_JSON=""
if [ -t 0 ]; then
  echo '{"error":"Cycle record JSON expected on stdin","stored":false}' && exit 0
fi
CYCLE_JSON=$(cat)

if [ -z "$CYCLE_JSON" ] || ! echo "$CYCLE_JSON" | jq -e '.' >/dev/null 2>&1; then
  echo '{"error":"Invalid JSON on stdin","stored":false}' && exit 0
fi

# --- Step 1: Validate required fields ---
validate_cycle() {
  local record="$1"
  local errors='[]'

  # Check required top-level fields
  for field in version cycle_id timestamp phases outcome metrics; do
    if ! echo "$record" | jq -e ".$field" >/dev/null 2>&1; then
      errors=$(echo "$errors" | jq -c --arg f "$field" '. + ["missing required field: " + $f]')
    fi
  done

  # Check required phases
  for phase in test learn practice apply evaluate; do
    if ! echo "$record" | jq -e ".phases.$phase" >/dev/null 2>&1; then
      errors=$(echo "$errors" | jq -c --arg p "$phase" '. + ["missing phase: " + $p]')
    fi
  done

  local error_count
  error_count=$(echo "$errors" | jq 'length')

  if [ "$error_count" -gt 0 ]; then
    echo "$errors"
    return 1
  fi
  echo '[]'
  return 0
}

# --- Step 2: Write cycle record (append-only) ---
store_cycle() {
  local record="$1"
  local cycle_id
  cycle_id=$(echo "$record" | jq -r '.cycle_id')

  local cycle_file="$CYCLES_DIR/${cycle_id}.json"

  # NEVER overwrite existing cycle records
  if [ -f "$cycle_file" ]; then
    echo "exists"
    return 0
  fi

  mkdir -p "$CYCLES_DIR"
  echo "$record" | jq '.' > "$cycle_file"
  echo "stored"
}

# --- Step 3: Update task registry ---
update_task_registry() {
  local record="$1"
  local registry="$TASKS_DIR/registry.json"
  mkdir -p "$TASKS_DIR"

  [ -f "$registry" ] || echo '{"version":"2.0.0","tasks":{}}' > "$registry"

  local task_id
  task_id=$(echo "$record" | jq -r '.target_task.task_id // "unknown"')
  local status
  status=$(echo "$record" | jq -r '.outcome.status // "unknown"')
  local cycle_id
  cycle_id=$(echo "$record" | jq -r '.cycle_id')
  local imp_score
  imp_score=$(echo "$record" | jq -r '.outcome.improvement_score // 0')

  # Update registry
  local updated
  updated=$(jq --arg tid "$task_id" --arg status "$status" \
    --arg cid "$cycle_id" --argjson score "$imp_score" \
    --arg ts "$(now_iso)" '
    .tasks[$tid] = (
      (.tasks[$tid] // {cycles: [], first_seen: $ts}) + {
        status: $status,
        last_cycle: $cid,
        last_updated: $ts,
        improvement_score: $score,
        cycles: ((.tasks[$tid].cycles // []) + [$cid])
      }
    )
  ' "$registry" 2>/dev/null)

  if [ -n "$updated" ]; then
    echo "$updated" > "$registry"
  fi
}

# --- Step 4: Extract learning patterns ---
extract_patterns() {
  local record="$1"
  local patterns_count=0

  mkdir -p "$PATTERNS_DIR"

  local status
  status=$(echo "$record" | jq -r '.outcome.status // "unknown"')
  local cycle_id
  cycle_id=$(echo "$record" | jq -r '.cycle_id')
  local lessons
  lessons=$(echo "$record" | jq -c '.outcome.lessons_learned // []')
  local skills
  skills=$(echo "$record" | jq -c '.phases.learn.skills_installed // []')

  # Extract successful patterns
  if [ "$status" = "solved" ] || [ "$status" = "improved" ]; then
    local sp_file="$PATTERNS_DIR/successful-patterns.json"
    [ -f "$sp_file" ] || echo '{"version":"2.0.0","patterns":[]}' > "$sp_file"

    local pattern
    pattern=$(jq -n \
      --arg cid "$cycle_id" \
      --arg status "$status" \
      --argjson lessons "$lessons" \
      --argjson skills "$skills" \
      --arg ts "$(now_iso)" \
      '{cycle_id: $cid, status: $status, lessons: $lessons, skills_used: $skills, recorded_at: $ts}')

    jq --argjson p "$pattern" '.patterns += [$p]' "$sp_file" > "${sp_file}.tmp" && mv "${sp_file}.tmp" "$sp_file"
    patterns_count=$((patterns_count + 1))
  fi

  # Extract failed approaches
  if [ "$status" = "no_change" ] || [ "$status" = "degraded" ]; then
    local fa_file="$PATTERNS_DIR/failed-approaches.json"
    [ -f "$fa_file" ] || echo '{"version":"2.0.0","approaches":[]}' > "$fa_file"

    local approach
    approach=$(jq -n \
      --arg cid "$cycle_id" \
      --arg status "$status" \
      --argjson lessons "$lessons" \
      --argjson skills "$skills" \
      --arg ts "$(now_iso)" \
      '{cycle_id: $cid, status: $status, lessons: $lessons, skills_tried: $skills, recorded_at: $ts}')

    jq --argjson a "$approach" '.approaches += [$a]' "$fa_file" > "${fa_file}.tmp" && mv "${fa_file}.tmp" "$fa_file"
    patterns_count=$((patterns_count + 1))
  fi

  # Update skill effectiveness
  local se_file="$PATTERNS_DIR/skill-effectiveness.json"
  [ -f "$se_file" ] || echo '{"version":"2.0.0","skills":{}}' > "$se_file"

  local skill_list
  skill_list=$(echo "$skills" | jq -r '.[]' 2>/dev/null)
  local was_successful=false
  [ "$status" = "solved" ] || [ "$status" = "improved" ] && was_successful=true

  while IFS= read -r skill_name; do
    [ -z "$skill_name" ] && continue
    jq --arg s "$skill_name" --argjson success "$was_successful" '
      .skills[$s] = (
        (.skills[$s] // {total_uses: 0, successful_uses: 0}) |
        .total_uses += 1 |
        if $success then .successful_uses += 1 else . end |
        .effectiveness = (if .total_uses > 0 then (.successful_uses / .total_uses * 100 | round) else 0 end)
      )
    ' "$se_file" > "${se_file}.tmp" && mv "${se_file}.tmp" "$se_file"
    patterns_count=$((patterns_count + 1))
  done <<< "$skill_list"

  echo "$patterns_count"
}

# --- Step 5: Update latest snapshot ---
update_snapshot() {
  local record="$1"
  local snapshot_file="$SNAPSHOTS_DIR/latest.json"
  mkdir -p "$SNAPSHOTS_DIR"

  [ -f "$snapshot_file" ] || echo '{"version":"2.0.0","total_cycles":0,"last_cycle":null,"summary":{}}' > "$snapshot_file"

  local cycle_id
  cycle_id=$(echo "$record" | jq -r '.cycle_id')
  local status
  status=$(echo "$record" | jq -r '.outcome.status // "unknown"')
  local imp_score
  imp_score=$(echo "$record" | jq -r '.outcome.improvement_score // 0')

  jq --arg cid "$cycle_id" --arg status "$status" --argjson score "$imp_score" --arg ts "$(now_iso)" '
    .total_cycles += 1 |
    .last_cycle = $cid |
    .last_updated = $ts |
    .summary.total_cycles = .total_cycles |
    .summary.last_status = $status |
    .summary.last_improvement = $score |
    .summary[("status_" + $status)] = ((.summary[("status_" + $status)] // 0) + 1)
  ' "$snapshot_file" > "${snapshot_file}.tmp" && mv "${snapshot_file}.tmp" "$snapshot_file"
}

# --- Main ---
main() {
  local started_at
  started_at=$(now_iso)

  # Validate
  local validation_errors
  validation_errors=$(validate_cycle "$CYCLE_JSON")
  if [ "$?" -ne 0 ] 2>/dev/null; then
    if [ "$(echo "$validation_errors" | jq 'length' 2>/dev/null)" -gt 0 ]; then
      jq -n --argjson errors "$validation_errors" --arg ts "$(now_iso)" '{
        version: "2.0.0",
        phase: "evaluate",
        stored: false,
        validation_errors: $errors,
        started_at: $ts,
        completed_at: $ts
      }'
      exit 0
    fi
  fi

  # Store cycle
  local store_result
  store_result=$(store_cycle "$CYCLE_JSON")

  local cycle_id
  cycle_id=$(echo "$CYCLE_JSON" | jq -r '.cycle_id')

  # Update task registry
  update_task_registry "$CYCLE_JSON"

  # Extract patterns
  local patterns_extracted
  patterns_extracted=$(extract_patterns "$CYCLE_JSON")

  # Update snapshot
  update_snapshot "$CYCLE_JSON"

  # Count total cycles
  local total_cycles
  total_cycles=$(ls -1 "$CYCLES_DIR"/*.json 2>/dev/null | wc -l | tr -d ' ')

  # Output
  jq -n \
    --arg started_at "$started_at" \
    --arg completed_at "$(now_iso)" \
    --arg cycle_id "$cycle_id" \
    --arg stored_at "$CYCLES_DIR/${cycle_id}.json" \
    --arg store_result "$store_result" \
    --argjson patterns "$patterns_extracted" \
    --argjson total "$total_cycles" \
    '{
      version: "2.0.0",
      phase: "evaluate",
      started_at: $started_at,
      completed_at: $completed_at,
      cycle_id: $cycle_id,
      stored: ($store_result != "error"),
      stored_at: $stored_at,
      patterns_extracted: $patterns,
      total_cycles: $total
    }'
}

main "$@"
