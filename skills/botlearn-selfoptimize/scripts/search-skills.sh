#!/usr/bin/env bash
# search-skills.sh — 学阶段：多源技能搜索
# Searches local registry, npm @botlearn scope, and BotLearn community API
# for skills relevant to a given task. Scores and ranks candidates.
# Output: JSON with candidates and community_posts arrays to stdout
set -euo pipefail

# --- Configuration ---
OPENCLAW_HOME="${OPENCLAW_HOME:-$HOME/.openclaw}"
OPENCLAW_GATEWAY="${OPENCLAW_GATEWAY:-http://localhost:3000}"
BOTLEARN_API="https://botlearn.ai/api/community"
BOTLEARN_TOKEN="${BOTLEARN_TOKEN:-}"
NPM_REGISTRY="https://registry.npmjs.org"
TIMEOUT=15
MAX_RESULTS=10

# --- Scoring weights ---
W_KEYWORD=0.4
W_CATEGORY=0.2
W_COMMUNITY=0.2
W_RECENCY=0.2

# --- Parse arguments ---
KEYWORDS=""
TASK_TYPE=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --keywords) KEYWORDS="$2"; shift 2 ;;
    --task-type) TASK_TYPE="$2"; shift 2 ;;
    *) shift ;;
  esac
done

if [ -z "$KEYWORDS" ]; then
  echo '{"error":"--keywords is required","candidates":[],"community_posts":[]}' && exit 0
fi

# --- Helper ---
now_iso() { date -u +"%Y-%m-%dT%H:%M:%SZ"; }

api_get() {
  local url="$1"
  local auth_header="${2:-}"
  if [ -n "$auth_header" ]; then
    curl -sf --max-time "$TIMEOUT" -H "Content-Type: application/json" -H "Authorization: $auth_header" "$url" 2>/dev/null || echo '{"error":"request_failed"}'
  else
    curl -sf --max-time "$TIMEOUT" -H "Content-Type: application/json" "$url" 2>/dev/null || echo '{"error":"request_failed"}'
  fi
}

# --- Resolve BotLearn token from credentials file ---
resolve_token() {
  if [ -n "$BOTLEARN_TOKEN" ]; then
    echo "$BOTLEARN_TOKEN"
    return
  fi
  local cred_file="$HOME/.config/botlearn/credentials.json"
  if [ -f "$cred_file" ]; then
    jq -r '.api_key // ""' "$cred_file" 2>/dev/null || echo ""
  else
    echo ""
  fi
}

# --- Source 1: Local registry (installed skills) ---
search_local() {
  local result
  result=$(api_get "$OPENCLAW_GATEWAY/skills/list")

  if echo "$result" | jq -e '.error' >/dev/null 2>&1; then
    echo '[]'
    return
  fi

  local kw_lower
  kw_lower=$(echo "$KEYWORDS" | tr '[:upper:]' '[:lower:]')

  echo "$result" | jq -c --arg kw "$kw_lower" --arg tt "$TASK_TYPE" '
    [(.skills // [])[] | select(
      (.name | ascii_downcase | contains($kw)) or
      (.description // "" | ascii_downcase | contains($kw)) or
      (.tags // [] | map(ascii_downcase) | any(contains($kw)))
    ) | {
      name: .name,
      version: .version,
      description: .description,
      source: "local_registry",
      installed: true,
      relevance_score: 0
    }]
  ' 2>/dev/null || echo '[]'
}

# --- Source 2: npm @botlearn scope ---
search_npm() {
  # Search npm for @botlearn packages matching keywords
  local encoded_kw
  encoded_kw=$(echo "$KEYWORDS" | sed 's/ /+/g')
  local result
  result=$(curl -sf --max-time "$TIMEOUT" \
    "$NPM_REGISTRY/-/v1/search?text=@botlearn+$encoded_kw&size=20" 2>/dev/null || echo '{"objects":[]}')

  echo "$result" | jq -c '
    [(.objects // [])[] | {
      name: .package.name,
      version: .package.version,
      description: (.package.description // ""),
      source: "npm",
      installed: false,
      published_at: (.package.date // ""),
      relevance_score: 0
    } | select(.name | startswith("@botlearn/"))]
  ' 2>/dev/null || echo '[]'
}

# --- Source 3: BotLearn community search ---
search_community() {
  local token
  token=$(resolve_token)

  if [ -z "$token" ]; then
    echo '{"candidates":[],"posts":[]}'
    return
  fi

  local encoded_kw
  encoded_kw=$(echo "$KEYWORDS" | sed 's/ /%20/g')

  # Search skills via community API
  local search_result
  search_result=$(api_get "$BOTLEARN_API/search?q=$encoded_kw&type=skill" "Bearer $token")

  local candidates
  if echo "$search_result" | jq -e '.error' >/dev/null 2>&1; then
    candidates='[]'
  else
    candidates=$(echo "$search_result" | jq -c '
      [(.results // [])[] | {
        name: .name,
        version: (.version // "unknown"),
        description: (.description // ""),
        source: "botlearn_search",
        installed: false,
        endorsements: (.endorsements // 0),
        relevance_score: 0
      }]
    ' 2>/dev/null || echo '[]')
  fi

  # Also check community feed for relevant posts
  local feed_result
  feed_result=$(api_get "$BOTLEARN_API/feed?sort=hot&limit=20" "Bearer $token")

  local posts
  if echo "$feed_result" | jq -e '.error' >/dev/null 2>&1; then
    posts='[]'
  else
    local kw_lower
    kw_lower=$(echo "$KEYWORDS" | tr '[:upper:]' '[:lower:]')
    posts=$(echo "$feed_result" | jq -c --arg kw "$kw_lower" '
      [(.posts // [])[] | select(
        (.title // "" | ascii_downcase | contains($kw)) or
        (.body // "" | ascii_downcase | contains($kw))
      ) | {
        post_id: .id,
        title: .title,
        author: .author,
        score: (.score // 0),
        url: .url,
        created_at: .created_at
      }]
    ' 2>/dev/null || echo '[]')
  fi

  jq -n --argjson candidates "$candidates" --argjson posts "$posts" \
    '{ candidates: $candidates, posts: $posts }'
}

# --- Score and rank all candidates ---
score_candidates() {
  local candidates="$1"
  local kw_lower
  kw_lower=$(echo "$KEYWORDS" | tr '[:upper:]' '[:lower:]')

  echo "$candidates" | jq -c --arg kw "$kw_lower" --arg tt "$TASK_TYPE" \
    --argjson wk "$W_KEYWORD" --argjson wc "$W_CATEGORY" \
    --argjson we "$W_COMMUNITY" --argjson wr "$W_RECENCY" '
    [.[] | . + {
      relevance_score: (
        # Keyword match
        (if (.name // "" | ascii_downcase | contains($kw)) then 1.0
         elif (.description // "" | ascii_downcase | contains($kw)) then 0.7
         else 0.3 end) * $wk +
        # Category match
        (if $tt != "" and ((.category // "") == $tt) then 1.0
         elif $tt != "" and ((.description // "") | ascii_downcase | contains($tt | ascii_downcase)) then 0.5
         else 0.3 end) * $wc +
        # Community endorsement
        (if (.endorsements // 0) > 10 then 1.0
         elif (.endorsements // 0) > 5 then 0.7
         elif (.endorsements // 0) > 0 then 0.4
         else 0.2 end) * $we +
        # Recency (installed skills get a boost)
        (if .installed == true then 1.0
         elif .source == "local_registry" then 0.9
         else 0.5 end) * $wr
      )
    }] |
    sort_by(-.relevance_score) |
    unique_by(.name) |
    .[:'"$MAX_RESULTS"']
  ' 2>/dev/null || echo "$candidates"
}

# --- Main ---
main() {
  local started_at
  started_at=$(now_iso)

  # Search all sources
  local local_results npm_results community_data
  local_results=$(search_local)
  npm_results=$(search_npm)
  community_data=$(search_community)

  local community_candidates community_posts
  community_candidates=$(echo "$community_data" | jq -c '.candidates' 2>/dev/null || echo '[]')
  community_posts=$(echo "$community_data" | jq -c '.posts' 2>/dev/null || echo '[]')

  # Merge skill candidates
  local merged
  merged=$(echo "$local_results" "$npm_results" "$community_candidates" | jq -s 'add' 2>/dev/null || echo '[]')

  # Score and rank
  local scored
  scored=$(score_candidates "$merged")

  local count
  count=$(echo "$scored" | jq 'length' 2>/dev/null || echo 0)
  local posts_count
  posts_count=$(echo "$community_posts" | jq 'length' 2>/dev/null || echo 0)

  # Output
  jq -n \
    --arg started_at "$started_at" \
    --arg completed_at "$(now_iso)" \
    --arg keywords "$KEYWORDS" \
    --arg task_type "$TASK_TYPE" \
    --argjson candidates "$scored" \
    --argjson community_posts "$community_posts" \
    --argjson count "$count" \
    --argjson posts_count "$posts_count" \
    '{
      version: "2.0.0",
      phase: "learn",
      started_at: $started_at,
      completed_at: $completed_at,
      search_params: { keywords: $keywords, task_type: $task_type },
      sources_searched: ["local_registry", "npm", "botlearn_search", "botlearn_feed"],
      candidates_found: $count,
      candidates: $candidates,
      community_posts_found: $posts_count,
      community_posts: $community_posts
    }'
}

main "$@"
