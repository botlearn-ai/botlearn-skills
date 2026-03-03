#!/bin/bash
# track-browser.sh — Monitor browser visits to botlearn.ai domain
# Timeout: 10s | Compatible: macOS (darwin) + Linux
# Output: JSON to stdout
# Privacy: ONLY queries botlearn.ai domain. Copies DB to /tmp to avoid lock conflicts.
# This feature is entirely optional and degrades gracefully.
set -euo pipefail

DOMAIN="botlearn.ai"
TMP_DIR="/tmp/openclaw-graduate"

# --- Helper functions ---

ensure_tmp_dir() {
  mkdir -p "$TMP_DIR" 2>/dev/null || true
}

query_chrome_history() {
  local os_name
  os_name="$(uname -s)"
  local history_db=""

  if [[ "$os_name" == "Darwin" ]]; then
    history_db="$HOME/Library/Application Support/Google/Chrome/Default/History"
  else
    history_db="$HOME/.config/google-chrome/Default/History"
  fi

  if [[ ! -f "$history_db" ]]; then
    echo '{"available":false,"browser":"chrome","reason":"history_not_found"}'
    return
  fi

  # Copy DB to /tmp to avoid lock conflicts with running browser
  local tmp_db="${TMP_DIR}/chrome-history-copy"
  cp "$history_db" "$tmp_db" 2>/dev/null || {
    echo '{"available":false,"browser":"chrome","reason":"copy_failed"}'
    return
  }

  # Query only botlearn.ai domain visits
  local result
  result=$(sqlite3 "$tmp_db" "
    SELECT
      COUNT(*) as visit_count,
      MIN(datetime(last_visit_time/1000000-11644473600, 'unixepoch')) as first_visit,
      MAX(datetime(last_visit_time/1000000-11644473600, 'unixepoch')) as last_visit
    FROM urls
    WHERE url LIKE '%${DOMAIN}%'
  " 2>/dev/null || echo "")

  # Clean up
  rm -f "$tmp_db" 2>/dev/null || true

  if [[ -z "$result" ]]; then
    echo '{"available":true,"browser":"chrome","visits":0,"firstVisit":null,"lastVisit":null}'
    return
  fi

  local visit_count first_visit last_visit
  visit_count=$(echo "$result" | cut -d'|' -f1)
  first_visit=$(echo "$result" | cut -d'|' -f2)
  last_visit=$(echo "$result" | cut -d'|' -f3)

  # Get unique page paths
  local tmp_db2="${TMP_DIR}/chrome-history-copy2"
  cp "$history_db" "$tmp_db2" 2>/dev/null || true
  local pages
  pages=$(sqlite3 "$tmp_db2" "
    SELECT DISTINCT url FROM urls
    WHERE url LIKE '%${DOMAIN}%'
    ORDER BY last_visit_time DESC
    LIMIT 10
  " 2>/dev/null | jq -R -s 'split("\n") | map(select(length > 0))' 2>/dev/null || echo '[]')
  rm -f "$tmp_db2" 2>/dev/null || true

  cat <<INNER
{
  "available": true,
  "browser": "chrome",
  "visits": ${visit_count:-0},
  "firstVisit": "${first_visit:-null}",
  "lastVisit": "${last_visit:-null}",
  "uniquePages": $pages
}
INNER
}

query_safari_history() {
  local os_name
  os_name="$(uname -s)"
  if [[ "$os_name" != "Darwin" ]]; then
    echo '{"available":false,"browser":"safari","reason":"not_macos"}'
    return
  fi

  local history_db="$HOME/Library/Safari/History.db"
  if [[ ! -f "$history_db" ]]; then
    echo '{"available":false,"browser":"safari","reason":"history_not_found"}'
    return
  fi

  # Copy DB to /tmp
  local tmp_db="${TMP_DIR}/safari-history-copy"
  cp "$history_db" "$tmp_db" 2>/dev/null || {
    echo '{"available":false,"browser":"safari","reason":"copy_failed"}'
    return
  }

  local result
  result=$(sqlite3 "$tmp_db" "
    SELECT
      COUNT(*) as visit_count,
      MIN(datetime(visit_time + 978307200, 'unixepoch')) as first_visit,
      MAX(datetime(visit_time + 978307200, 'unixepoch')) as last_visit
    FROM history_visits
    JOIN history_items ON history_visits.history_item = history_items.id
    WHERE history_items.url LIKE '%${DOMAIN}%'
  " 2>/dev/null || echo "")

  rm -f "$tmp_db" 2>/dev/null || true

  if [[ -z "$result" ]]; then
    echo '{"available":true,"browser":"safari","visits":0,"firstVisit":null,"lastVisit":null}'
    return
  fi

  local visit_count first_visit last_visit
  visit_count=$(echo "$result" | cut -d'|' -f1)
  first_visit=$(echo "$result" | cut -d'|' -f2)
  last_visit=$(echo "$result" | cut -d'|' -f3)

  cat <<INNER
{
  "available": true,
  "browser": "safari",
  "visits": ${visit_count:-0},
  "firstVisit": "${first_visit:-null}",
  "lastVisit": "${last_visit:-null}"
}
INNER
}

# --- Main ---

ensure_tmp_dir

CHROME_JSON=$(query_chrome_history)
SAFARI_JSON=$(query_safari_history)

# Calculate total
CHROME_VISITS=$(echo "$CHROME_JSON" | jq '.visits // 0' 2>/dev/null || echo 0)
SAFARI_VISITS=$(echo "$SAFARI_JSON" | jq '.visits // 0' 2>/dev/null || echo 0)
TOTAL_VISITS=$((CHROME_VISITS + SAFARI_VISITS))

cat <<EOF
{
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "domain": "$DOMAIN",
  "privacy": "Only queries ${DOMAIN} domain. DB copied to /tmp before query.",
  "browsers": {
    "chrome": $CHROME_JSON,
    "safari": $SAFARI_JSON
  },
  "totalVisits": $TOTAL_VISITS,
  "engaged": $(if [[ $TOTAL_VISITS -gt 0 ]]; then echo "true"; else echo "false"; fi)
}
EOF

# Clean up tmp dir
rm -rf "$TMP_DIR" 2>/dev/null || true
