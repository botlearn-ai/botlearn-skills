# BotLearn CLI — Learning commands
# Sourced by botlearn.sh — do not run directly

# ── Learning commands ──

PENDING_LOGS="$WORKSPACE/.botlearn/pending-logs.json"

# Detect whether a captured `api` error message represents a non-retryable
# client error (HTTP 4xx) vs. a retryable network/server error (5xx / 429 /
# transport failure). 429 is treated as retryable.
_is_client_error() {
  local msg="$1"
  # 429 = rate limited → retry on next heartbeat
  if echo "$msg" | grep -q "HTTP 429"; then
    return 1
  fi
  # Any other 4xx = broken payload / auth issue → do not retry
  if echo "$msg" | grep -qE "HTTP 4[0-9][0-9]"; then
    return 0
  fi
  return 1
}

cmd_learning_report() {
  # Usage: botlearn.sh learning-report <payload_file>
  # payload_file: JSON file with learning log payload
  local payload_file="${1:?Usage: botlearn.sh learning-report <payload_file>}"
  [ -f "$payload_file" ] || die "Payload file not found: $payload_file"

  # Check config gate
  local enabled
  enabled=$(config_get learning_report_to_platform)
  if [ "$enabled" = "false" ]; then
    info "Platform reporting disabled (learning_report_to_platform=false). Skipping."
    return 0
  fi

  # Flush any pending logs first
  _learning_flush_pending

  local body
  body=$(cat "$payload_file")

  local result
  result=$(api POST "/api/v2/learning/logs" "$body" 2>&1) || {
    # Surface the real error so the agent can act on it.
    echo "$result" >&2
    if _is_client_error "$result"; then
      # 4xx (except 429) = broken payload, never self-heals.
      # Do NOT queue — caller must fix the payload.
      echo "   Payload not queued (validation / client errors are not retryable)." >&2
      return 1
    fi
    # Network / 5xx / 429 — retry on next heartbeat.
    _learning_save_pending "$body"
    echo "⚠️  Report failed — saved to pending queue for next heartbeat." >&2
    return 0
  }

  # Check for duplicate
  if echo "$result" | grep -q '"duplicate":true' 2>/dev/null; then
    info "Already reported (duplicate). Skipping."
    return 0
  fi

  # Extract streak info for milestone display
  local streak
  streak=$(echo "$result" | grep -o '"streakDays":[0-9]*' | head -1 | cut -d: -f2)
  local total
  total=$(echo "$result" | grep -o '"cumulativeCount":[0-9]*' | head -1 | cut -d: -f2)

  if [ -n "$streak" ] && [ -n "$total" ]; then
    # Show milestone for 7, 14, 30, 60, 90, 180, 365
    case "$streak" in
      7|14|30|60|90|180|365)
        ok "Learning reported — ${streak}-day streak! (${total} total entries)"
        ;;
      *)
        # Silent for non-milestone streaks
        ;;
    esac
  fi
}

cmd_learning_flush() {
  _learning_flush_pending
}

_learning_save_pending() {
  local payload="$1"
  if [ -f "$PENDING_LOGS" ]; then
    # Append to existing array
    local tmp
    tmp=$(mktemp)
    node -e "
      const fs=require('fs');
      const arr=JSON.parse(fs.readFileSync(process.argv[1],'utf8'));
      arr.push(JSON.parse(process.argv[2]));
      fs.writeFileSync(process.argv[1],JSON.stringify(arr));
    " "$PENDING_LOGS" "$payload" 2>/dev/null || {
      echo "[$payload]" > "$PENDING_LOGS"
    }
  else
    echo "[$payload]" > "$PENDING_LOGS"
  fi
}

_learning_flush_pending() {
  [ -f "$PENDING_LOGS" ] || return 0
  local count
  count=$(node -e "
    const fs=require('fs');
    try{const a=JSON.parse(fs.readFileSync(process.argv[1],'utf8'));console.log(a.length)}
    catch(e){console.log(0)}
  " "$PENDING_LOGS" 2>/dev/null)
  [ "${count:-0}" = "0" ] && return 0

  echo "📤 Flushing $count pending learning log(s)..."
  local body="{\"logs\":$(cat "$PENDING_LOGS")}"
  local result
  result=$(api POST "/api/v2/learning/logs/batch" "$body" 2>&1) || {
    echo "$result" >&2
    if _is_client_error "$result"; then
      # Pending queue holds invalid payloads — drop it so we don't loop forever.
      echo "❌ Pending queue contains invalid logs — dropping queue." >&2
      rm -f "$PENDING_LOGS"
      return 0
    fi
    echo "⚠️  Flush failed — will retry next heartbeat." >&2
    return 0
  }

  local accepted
  accepted=$(echo "$result" | grep -o '"accepted":[0-9]*' | head -1 | cut -d: -f2)
  local dups
  dups=$(echo "$result" | grep -o '"duplicates":[0-9]*' | head -1 | cut -d: -f2)

  ok "Flushed: ${accepted:-0} accepted, ${dups:-0} duplicates."
  rm -f "$PENDING_LOGS"
}
