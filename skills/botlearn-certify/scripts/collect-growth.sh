#!/bin/bash
# collect-growth.sh — Calculate 4C growth dimensions, compare against Day 1 baseline
# Timeout: 15s | Compatible: macOS (darwin) + Linux
# Output: JSON to stdout
# Dimensions: Core (15%) / Context (35%) / Constitution (20%) / Capabilities (30%)
set -euo pipefail

OPENCLAW_HOME="${OPENCLAW_HOME:-$HOME/.openclaw}"
GRADUATE_DATA="${OPENCLAW_HOME}/data/graduate"

# --- Core Dimension (15%) ---

score_core() {
  local score=0
  local config_file="${OPENCLAW_HOME}/config/openclaw.config.json"

  # model_appropriate: check if model is configured (not default)
  if [[ -f "$config_file" ]]; then
    local model
    model=$(jq -r '.execution.model // ""' "$config_file" 2>/dev/null || echo "")
    if [[ -n "$model" && "$model" != "null" && "$model" != "default" ]]; then
      score=$((score + 30))
    fi
    # configuration_optimized: check for custom settings beyond defaults
    local custom_keys
    custom_keys=$(jq 'keys | length' "$config_file" 2>/dev/null || echo 0)
    if [[ "$custom_keys" -gt 2 ]]; then
      score=$((score + 40))
    fi
    # cost_effective: config exists = some cost awareness
    score=$((score + 30))
  fi

  echo "$score"
}

# --- Context Dimension (35%) ---

score_context() {
  local score=0

  # document_count (0-30 points)
  local doc_count=0
  for dir in "$OPENCLAW_HOME/workspace" "$OPENCLAW_HOME/memory" "$OPENCLAW_HOME/data"; do
    if [[ -d "$dir" ]]; then
      local count
      count=$(find "$dir" -type f \( -name "*.md" -o -name "*.txt" -o -name "*.json" \) 2>/dev/null | wc -l | tr -d ' ')
      doc_count=$((doc_count + count))
    fi
  done
  if [[ $doc_count -ge 21 ]]; then score=$((score + 30))
  elif [[ $doc_count -ge 11 ]]; then score=$((score + 24))
  elif [[ $doc_count -ge 6 ]]; then score=$((score + 18))
  elif [[ $doc_count -ge 1 ]]; then score=$((score + 12))
  fi

  # memory_structure (0-40 points)
  local memory_dir="$OPENCLAW_HOME/memory"
  if [[ -d "$memory_dir" ]]; then
    local mem_files
    mem_files=$(find "$memory_dir" -type f 2>/dev/null | wc -l | tr -d ' ')
    if [[ "$mem_files" -gt 0 ]]; then
      score=$((score + 40))
    fi
  fi

  # personalization_depth (0-30 points)
  local personalized=false
  for f in "SOUL.md" "USER.md"; do
    for dir in "." "$OPENCLAW_HOME" "$OPENCLAW_HOME/workspace"; do
      if [[ -f "$dir/$f" ]]; then
        local size
        size=$(wc -c < "$dir/$f" 2>/dev/null | tr -d ' ')
        if [[ "$size" -gt 100 ]]; then
          personalized=true
          break
        fi
      fi
    done
  done
  if [[ "$personalized" == "true" ]]; then
    score=$((score + 30))
  fi

  echo "$score"
}

# --- Constitution Dimension (20%) ---

score_constitution() {
  local score=0

  check_file_quality() {
    local file_name="$1"
    local max_points="$2"
    for dir in "." "$OPENCLAW_HOME" "$OPENCLAW_HOME/workspace"; do
      if [[ -f "$dir/$file_name" ]]; then
        local size
        size=$(wc -c < "$dir/$file_name" 2>/dev/null | tr -d ' ')
        if [[ "$size" -gt 200 ]]; then
          echo "$max_points"
          return
        elif [[ "$size" -gt 50 ]]; then
          echo $((max_points * 6 / 10))
          return
        else
          echo $((max_points * 3 / 10))
          return
        fi
      fi
    done
    echo 0
  }

  local soul_score
  soul_score=$(check_file_quality "SOUL.md" 35)
  local user_score
  user_score=$(check_file_quality "USER.md" 35)
  local agents_score
  agents_score=$(check_file_quality "AGENTS.md" 30)

  score=$((soul_score + user_score + agents_score))
  echo "$score"
}

# --- Capabilities Dimension (30%) ---

score_capabilities() {
  local score=0
  local skills_dir="${OPENCLAW_HOME}/skills"

  # relevant_skills (0-40 points)
  local skill_count=0
  if [[ -d "$skills_dir" ]]; then
    skill_count=$(find "$skills_dir" -maxdepth 1 -mindepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')
  fi
  if [[ $skill_count -ge 11 ]]; then score=$((score + 40))
  elif [[ $skill_count -ge 6 ]]; then score=$((score + 32))
  elif [[ $skill_count -ge 3 ]]; then score=$((score + 24))
  elif [[ $skill_count -ge 1 ]]; then score=$((score + 12))
  fi

  # skill_usage (0-30 points) — estimated from log presence
  local log_dir="${OPENCLAW_HOME}/logs"
  if [[ -d "$log_dir" ]]; then
    local log_count
    log_count=$(find "$log_dir" -name "*.log" -o -name "*.jsonl" 2>/dev/null | wc -l | tr -d ' ')
    if [[ "$log_count" -gt 20 ]]; then score=$((score + 30))
    elif [[ "$log_count" -gt 10 ]]; then score=$((score + 20))
    elif [[ "$log_count" -gt 0 ]]; then score=$((score + 10))
    fi
  fi

  # effective_combinations (0-30 points) — multi-skill usage indicator
  if [[ $skill_count -ge 3 ]]; then
    score=$((score + 30))
  elif [[ $skill_count -ge 2 ]]; then
    score=$((score + 15))
  fi

  echo "$score"
}

# --- Load baseline for comparison ---

get_baseline_scores() {
  local baseline_file="${GRADUATE_DATA}/day1-baseline.json"
  if [[ -f "$baseline_file" ]]; then
    jq -r '{core: (.core // 0), context: (.context // 0), constitution: (.constitution // 0), capabilities: (.capabilities // 0), overall: (.overall // 0)}' "$baseline_file" 2>/dev/null || echo '{"core":0,"context":0,"constitution":0,"capabilities":0,"overall":0}'
  else
    echo '{"core":0,"context":0,"constitution":0,"capabilities":0,"overall":0}'
  fi
}

# --- Calculate scores ---

CORE=$(score_core)
CONTEXT=$(score_context)
CONSTITUTION=$(score_constitution)
CAPABILITIES=$(score_capabilities)

# Weighted overall: Core 15% + Context 35% + Constitution 20% + Capabilities 30%
OVERALL=$(node -e "
  const c = ${CORE}, cx = ${CONTEXT}, cn = ${CONSTITUTION}, ca = ${CAPABILITIES};
  const overall = Math.round(c * 0.15 + cx * 0.35 + cn * 0.20 + ca * 0.30);
  console.log(overall);
" 2>/dev/null || echo 0)

BASELINE_JSON=$(get_baseline_scores)

# --- Output ---

cat <<EOF
{
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "current": {
    "core": $CORE,
    "context": $CONTEXT,
    "constitution": $CONSTITUTION,
    "capabilities": $CAPABILITIES,
    "overall": $OVERALL
  },
  "baseline": $BASELINE_JSON,
  "growth": {
    "core": $(echo "$BASELINE_JSON" | jq "($CORE - .core)"),
    "context": $(echo "$BASELINE_JSON" | jq "($CONTEXT - .context)"),
    "constitution": $(echo "$BASELINE_JSON" | jq "($CONSTITUTION - .constitution)"),
    "capabilities": $(echo "$BASELINE_JSON" | jq "($CAPABILITIES - .capabilities)"),
    "overall": $(echo "$BASELINE_JSON" | jq "($OVERALL - .overall)")
  },
  "weights": {
    "core": 0.15,
    "context": 0.35,
    "constitution": 0.20,
    "capabilities": 0.30
  }
}
EOF
