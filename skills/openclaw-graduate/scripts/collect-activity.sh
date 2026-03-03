#!/bin/bash
# collect-activity.sh — Collect botlearn.ai community activity via API
# Timeout: 10s | Compatible: macOS (darwin) + Linux
# Output: JSON to stdout
# Degrades gracefully if credentials not available
set -euo pipefail

BOTLEARN_HOME="${BOTLEARN_HOME:-$HOME/.botlearn}"
BOTLEARN_API_URL="${BOTLEARN_API_URL:-https://api.botlearn.ai}"
CREDENTIALS_FILE="${BOTLEARN_HOME}/credentials.json"

# --- Helper functions ---

check_credentials() {
  if [[ ! -f "$CREDENTIALS_FILE" ]]; then
    echo "false"
    return
  fi
  local token
  token=$(jq -r '.apiToken // .token // empty' "$CREDENTIALS_FILE" 2>/dev/null || echo "")
  if [[ -n "$token" ]]; then
    echo "true"
  else
    echo "false"
  fi
}

get_api_token() {
  jq -r '.apiToken // .token // empty' "$CREDENTIALS_FILE" 2>/dev/null || echo ""
}

get_username() {
  jq -r '.username // .user // empty' "$CREDENTIALS_FILE" 2>/dev/null || echo ""
}

fetch_activity() {
  local token
  token=$(get_api_token)
  if [[ -z "$token" ]]; then
    echo '{"available":false,"reason":"no_token"}'
    return
  fi

  # Fetch user activity summary from botlearn.ai API
  local response
  response=$(curl -s --max-time 5 \
    -H "Authorization: Bearer $token" \
    -H "Content-Type: application/json" \
    "${BOTLEARN_API_URL}/v1/user/activity" 2>/dev/null || echo "")

  if [[ -z "$response" ]]; then
    echo '{"available":false,"reason":"api_unreachable"}'
    return
  fi

  # Validate JSON response
  if ! echo "$response" | jq . >/dev/null 2>&1; then
    echo '{"available":false,"reason":"invalid_response"}'
    return
  fi

  # Extract activity metrics
  local posts comments follows likes
  posts=$(echo "$response" | jq '.posts // 0' 2>/dev/null || echo 0)
  comments=$(echo "$response" | jq '.comments // 0' 2>/dev/null || echo 0)
  follows=$(echo "$response" | jq '.follows // 0' 2>/dev/null || echo 0)
  likes=$(echo "$response" | jq '.likes // 0' 2>/dev/null || echo 0)

  cat <<INNER
{
  "available": true,
  "posts": $posts,
  "comments": $comments,
  "follows": $follows,
  "likes": $likes,
  "engagementScore": $(( posts * 5 + comments * 3 + follows * 2 + likes ))
}
INNER
}

# --- Main ---

HAS_CREDENTIALS=$(check_credentials)
USERNAME=$(get_username)

if [[ "$HAS_CREDENTIALS" == "true" ]]; then
  ACTIVITY_JSON=$(fetch_activity)
else
  ACTIVITY_JSON='{"available":false,"reason":"no_credentials"}'
fi

cat <<EOF
{
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "botlearn": {
    "credentialsConfigured": $HAS_CREDENTIALS,
    "username": "${USERNAME:-null}",
    "apiUrl": "$BOTLEARN_API_URL"
  },
  "activity": $ACTIVITY_JSON
}
EOF
