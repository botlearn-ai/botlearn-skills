#!/usr/bin/env bash
# notify-owner.sh — 用阶段：通知主人
# Sends structured notifications to the agent's owner via OpenClaw Gateway.
# Supports 4 notification types with action buttons.
# Falls back to pending-notifications queue on delivery failure.
# Output: JSON with delivery_status and notification_id to stdout
set -euo pipefail

# --- Configuration ---
OPENCLAW_HOME="${OPENCLAW_HOME:-$HOME/.openclaw}"
OPENCLAW_GATEWAY="${OPENCLAW_GATEWAY:-http://localhost:3000}"
DATA_DIR="$OPENCLAW_HOME/data/self-learn"
TIMEOUT=10

# --- Parse arguments ---
NOTIFY_TYPE=""
NOTIFY_DATA=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --type) NOTIFY_TYPE="$2"; shift 2 ;;
    --data) NOTIFY_DATA="$2"; shift 2 ;;
    *) shift ;;
  esac
done

VALID_TYPES="cycle-complete task-solved needs-approval error"
if [ -z "$NOTIFY_TYPE" ] || ! echo "$VALID_TYPES" | grep -qw "$NOTIFY_TYPE"; then
  echo '{"error":"--type must be one of: cycle-complete, task-solved, needs-approval, error","delivery_status":"failed"}' && exit 0
fi

if [ -z "$NOTIFY_DATA" ]; then
  echo '{"error":"--data JSON is required","delivery_status":"failed"}' && exit 0
fi

# --- Helper ---
now_iso() { date -u +"%Y-%m-%dT%H:%M:%SZ"; }

generate_id() {
  local ts
  ts=$(date +%Y%m%d%H%M%S)
  local rand
  rand=$(head -c 4 /dev/urandom | od -An -tx1 | tr -d ' \n' | head -c 4)
  echo "notif-${ts}-${rand}"
}

# --- Build notification payload by type ---
build_payload() {
  local ntype="$1"
  local data="$2"
  local notif_id="$3"

  case "$ntype" in
    cycle-complete)
      echo "$data" | jq -c --arg id "$notif_id" --arg ts "$(now_iso)" '{
        notification_id: $id,
        type: "cycle-complete",
        timestamp: $ts,
        title: "📚 Learning Cycle Complete",
        summary: ("Cycle " + (.cycle_id // "unknown") + ": " + (.status // "completed")),
        body: {
          cycle_id: .cycle_id,
          status: .status,
          improvement_score: .improvement_score,
          task_summary: .task_summary,
          skills_installed: (.skills_installed // []),
          lessons_learned: (.lessons_learned // [])
        },
        actions: [
          { id: "view-details", label: "View Details", type: "link" },
          { id: "rate-cycle", label: "Rate This Cycle", type: "input", input_type: "rating" },
          { id: "pause-learning", label: "Pause Learning", type: "button" }
        ],
        priority: "normal"
      }'
      ;;
    task-solved)
      echo "$data" | jq -c --arg id "$notif_id" --arg ts "$(now_iso)" '{
        notification_id: $id,
        type: "task-solved",
        timestamp: $ts,
        title: "✅ Task Solved!",
        summary: ("Successfully resolved: " + (.task_summary // "a previous task")),
        body: {
          task_id: .task_id,
          original_request: .original_request,
          solution_approach: .solution_approach,
          skills_used: (.skills_used // []),
          improvement_score: .improvement_score
        },
        actions: [
          { id: "view-solution", label: "View Solution", type: "link" },
          { id: "rate-solution", label: "Rate Solution", type: "input", input_type: "rating" }
        ],
        priority: "normal"
      }'
      ;;
    needs-approval)
      echo "$data" | jq -c --arg id "$notif_id" --arg ts "$(now_iso)" '{
        notification_id: $id,
        type: "needs-approval",
        timestamp: $ts,
        title: "🔔 Approval Needed",
        summary: ("Action requires your approval: " + (.action_description // "unknown action")),
        body: {
          action_type: .action_type,
          action_description: .action_description,
          details: .details,
          risk_level: (.risk_level // "low"),
          timeout_minutes: (.timeout_minutes // 60)
        },
        actions: [
          { id: "approve", label: "Approve", type: "button", style: "primary" },
          { id: "reject", label: "Reject", type: "button", style: "danger" },
          { id: "view-details", label: "View Details", type: "link" }
        ],
        priority: "high"
      }'
      ;;
    error)
      echo "$data" | jq -c --arg id "$notif_id" --arg ts "$(now_iso)" '{
        notification_id: $id,
        type: "error",
        timestamp: $ts,
        title: "⚠️ Learning Error",
        summary: ("Error in " + (.phase // "unknown") + " phase: " + (.error_message // "unknown error")),
        body: {
          phase: .phase,
          error_message: .error_message,
          impact: .impact,
          recovery_suggestion: .recovery_suggestion,
          cycle_id: .cycle_id
        },
        actions: [
          { id: "retry", label: "Retry", type: "button" },
          { id: "view-logs", label: "View Logs", type: "link" },
          { id: "dismiss", label: "Dismiss", type: "button" }
        ],
        priority: "high"
      }'
      ;;
  esac
}

# --- Send notification via Gateway ---
send_notification() {
  local payload="$1"

  local result
  result=$(curl -sf --max-time "$TIMEOUT" -X POST \
    -H "Content-Type: application/json" \
    -d "$payload" \
    "$OPENCLAW_GATEWAY/notifications/send" 2>/dev/null || echo '{"error":"delivery_failed"}')

  echo "$result"
}

# --- Fallback: queue notification for retry ---
queue_notification() {
  local payload="$1"
  local pending_file="$DATA_DIR/pending-notifications.json"

  # Ensure the file exists
  [ -f "$pending_file" ] || echo '[]' > "$pending_file"

  # Append to pending queue
  local updated
  updated=$(jq -c --argjson new "$payload" '. + [$new + {queued_at: (now | todate), retry_count: 0}]' "$pending_file" 2>/dev/null)

  if [ -n "$updated" ]; then
    echo "$updated" > "$pending_file"
    return 0
  fi
  return 1
}

# --- Main ---
main() {
  local started_at
  started_at=$(now_iso)

  local notif_id
  notif_id=$(generate_id)

  # Build notification payload
  local payload
  payload=$(build_payload "$NOTIFY_TYPE" "$NOTIFY_DATA" "$notif_id")

  if [ -z "$payload" ] || [ "$payload" = "null" ]; then
    jq -n --arg ts "$(now_iso)" '{
      version: "2.0.0",
      phase: "apply",
      delivery_status: "failed",
      error: "Failed to build notification payload",
      started_at: $ts,
      completed_at: $ts
    }'
    exit 0
  fi

  # Attempt delivery
  local result
  result=$(send_notification "$payload")

  local delivery_status="delivered"
  local final_notif_id="$notif_id"

  if echo "$result" | jq -e '.error' >/dev/null 2>&1; then
    # Delivery failed — queue for retry
    delivery_status="queued"
    if queue_notification "$payload"; then
      delivery_status="queued"
    else
      delivery_status="failed"
    fi
  else
    final_notif_id=$(echo "$result" | jq -r '.notification_id // "'"$notif_id"'"')
  fi

  # Output
  jq -n \
    --arg started_at "$started_at" \
    --arg completed_at "$(now_iso)" \
    --arg notif_id "$final_notif_id" \
    --arg type "$NOTIFY_TYPE" \
    --arg delivery_status "$delivery_status" \
    '{
      version: "2.0.0",
      phase: "apply",
      started_at: $started_at,
      completed_at: $completed_at,
      notification_id: $notif_id,
      notification_type: $type,
      delivery_status: $delivery_status
    }'
}

main "$@"
