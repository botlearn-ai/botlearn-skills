#!/usr/bin/env bash
# attempt-task.sh — 练阶段：重新尝试任务
# Loads original task context from Memory API, captures before/after state,
# re-executes the task with newly installed skills, and computes improvement.
# Output: JSON with before/after comparison and status to stdout
set -euo pipefail

# --- Configuration ---
OPENCLAW_HOME="${OPENCLAW_HOME:-$HOME/.openclaw}"
OPENCLAW_GATEWAY="${OPENCLAW_GATEWAY:-http://localhost:3000}"
TIMEOUT=30
EXECUTE_TIMEOUT=120

# --- Parse arguments ---
TASK_ID=""
SESSION_ID=""
NEW_SKILLS=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --task-id) TASK_ID="$2"; shift 2 ;;
    --session-id) SESSION_ID="$2"; shift 2 ;;
    --new-skills) NEW_SKILLS="$2"; shift 2 ;;
    *) shift ;;
  esac
done

if [ -z "$TASK_ID" ]; then
  echo '{"error":"--task-id is required","status":"error"}' && exit 0
fi

# --- Helper ---
now_iso() { date -u +"%Y-%m-%dT%H:%M:%SZ"; }

api_get() {
  curl -sf --max-time "$TIMEOUT" -H "Content-Type: application/json" "$1" 2>/dev/null || echo '{"error":"request_failed"}'
}

api_post() {
  local url="$1"
  local data="$2"
  curl -sf --max-time "$EXECUTE_TIMEOUT" -X POST \
    -H "Content-Type: application/json" \
    -d "$data" "$url" 2>/dev/null || echo '{"error":"request_failed"}'
}

# --- Step 1: Load original task context ---
load_task_context() {
  local result
  result=$(api_get "$OPENCLAW_GATEWAY/memory/sessions/$SESSION_ID")

  if echo "$result" | jq -e '.error' >/dev/null 2>&1; then
    # Fallback: try by task_id
    result=$(api_get "$OPENCLAW_GATEWAY/memory/tasks/$TASK_ID")
  fi

  if echo "$result" | jq -e '.error' >/dev/null 2>&1; then
    echo '{"request":"unknown","context":{}}'
    return
  fi

  echo "$result" | jq -c '{
    request: (.request // .original_request // "unknown"),
    context: (.context // {}),
    parameters: (.parameters // {})
  }' 2>/dev/null || echo '{"request":"unknown","context":{}}'
}

# --- Step 2: Capture before state ---
capture_before_state() {
  local session_data="$1"

  # Get satisfaction, completeness, and error count from session
  local result
  result=$(api_get "$OPENCLAW_GATEWAY/memory/sessions/$SESSION_ID/metrics")

  if echo "$result" | jq -e '.error' >/dev/null 2>&1; then
    # Construct from available data
    echo '{"satisfaction":0.0,"completeness":0.0,"error_count":1}'
    return
  fi

  echo "$result" | jq -c '{
    satisfaction: (.satisfaction // 0),
    completeness: (.completeness // 0),
    error_count: (.error_count // (.errors | length) // 1)
  }' 2>/dev/null || echo '{"satisfaction":0.0,"completeness":0.0,"error_count":1}'
}

# --- Step 3: Re-execute task with new skills ---
execute_task() {
  local task_context="$1"
  local request
  request=$(echo "$task_context" | jq -r '.request')
  local context
  context=$(echo "$task_context" | jq -c '.context')

  local payload
  payload=$(jq -n \
    --arg task_id "$TASK_ID" \
    --arg request "$request" \
    --argjson context "$context" \
    --arg skills "$NEW_SKILLS" \
    '{
      task_id: $task_id,
      request: $request,
      context: $context,
      preferred_skills: ($skills | split(",") | map(select(. != ""))),
      source: "self-learn-reattempt"
    }')

  local result
  result=$(api_post "$OPENCLAW_GATEWAY/skills/execute" "$payload")

  echo "$result"
}

# --- Step 4: Capture after state ---
capture_after_state() {
  local exec_result="$1"

  if echo "$exec_result" | jq -e '.error' >/dev/null 2>&1; then
    echo '{"satisfaction":0.0,"completeness":0.0,"error_count":1}'
    return
  fi

  echo "$exec_result" | jq -c '{
    satisfaction: (.satisfaction // .quality_score // 0),
    completeness: (.completeness // .completion_rate // 0),
    error_count: (.error_count // (.errors | length) // 0)
  }' 2>/dev/null || echo '{"satisfaction":0.0,"completeness":0.0,"error_count":1}'
}

# --- Step 5: Calculate improvement score ---
calculate_improvement() {
  local before="$1"
  local after="$2"

  # Weights from scoring-model.json
  local W_COMPLETENESS=0.35
  local W_ERROR=0.25
  local W_QUALITY=0.25
  local W_OWNER=0.15

  node -e "
    const before = $before;
    const after = $after;
    const completeness_delta = after.completeness - before.completeness;
    const error_reduction = before.error_count > 0 ?
      1 - (after.error_count / before.error_count) : 0;
    const quality_delta = after.satisfaction - before.satisfaction;
    const owner_sat = 0.5; // neutral until owner rates

    const score = (completeness_delta * $W_COMPLETENESS) +
                  (Math.max(0, error_reduction) * $W_ERROR) +
                  (quality_delta * $W_QUALITY) +
                  (owner_sat * $W_OWNER);

    let status;
    if (score >= 0.7) status = 'solved';
    else if (score >= 0.1) status = 'improved';
    else if (score >= -0.1) status = 'no_change';
    else status = 'degraded';

    console.log(JSON.stringify({
      improvement_score: Math.round(score * 1000) / 1000,
      status: status
    }));
  " 2>/dev/null || echo '{"improvement_score":0,"status":"no_change"}'
}

# --- Main ---
main() {
  local started_at
  started_at=$(now_iso)

  # Load task context
  local task_context
  task_context=$(load_task_context)

  # Capture before state
  local before_state
  before_state=$(capture_before_state "$task_context")

  # Execute task
  local exec_result
  exec_result=$(execute_task "$task_context")

  # Capture after state
  local after_state
  after_state=$(capture_after_state "$exec_result")

  # Calculate improvement
  local improvement
  improvement=$(calculate_improvement "$before_state" "$after_state")

  local imp_score
  imp_score=$(echo "$improvement" | jq -r '.improvement_score')
  local status
  status=$(echo "$improvement" | jq -r '.status')

  # Determine if rollback is needed
  local rolled_back=false
  local rollback_reason="null"
  if [ "$status" = "degraded" ]; then
    rolled_back=true
    rollback_reason='"Task performance degraded after reattempt — reverting to previous state"'
    # Signal rollback to agent (agent handles the actual rollback)
  fi

  # Output
  jq -n \
    --arg started_at "$started_at" \
    --arg completed_at "$(now_iso)" \
    --arg task_id "$TASK_ID" \
    --arg session_id "$SESSION_ID" \
    --arg new_skills "$NEW_SKILLS" \
    --argjson before "$before_state" \
    --argjson after "$after_state" \
    --argjson imp_score "$imp_score" \
    --arg status "$status" \
    --argjson rolled_back "$rolled_back" \
    --argjson rollback_reason "$rollback_reason" \
    '{
      version: "2.0.0",
      phase: "practice",
      started_at: $started_at,
      completed_at: $completed_at,
      task_id: $task_id,
      session_id: $session_id,
      new_skills: ($new_skills | split(",") | map(select(. != ""))),
      before_state: $before,
      after_state: $after,
      improvement_score: $imp_score,
      status: $status,
      rolled_back: $rolled_back,
      rollback_reason: $rollback_reason
    }'
}

main "$@"
