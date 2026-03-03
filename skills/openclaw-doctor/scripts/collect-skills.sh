#!/bin/bash
# collect-skills.sh — Scan installed skills status, output JSON
# Timeout: 10s | Compatible: macOS (darwin) + Linux
set -euo pipefail

OPENCLAW_HOME="${OPENCLAW_HOME:-$HOME/.openclaw}"
SKILLS_DIR="${OPENCLAW_SKILLS_DIR:-$OPENCLAW_HOME/skills}"

skills_dir_exists="false"
installed_count=0
skill_list="[]"
outdated="[]"
broken_deps="[]"
unused_skills="[]"

if [[ -d "$SKILLS_DIR" ]]; then
  skills_dir_exists="true"

  # Count and list installed skills
  if [[ -d "$SKILLS_DIR/@botlearn" ]]; then
    skill_list=$(ls -d "$SKILLS_DIR/@botlearn"/*/ 2>/dev/null | while read -r dir; do
      name=$(basename "$dir")
      version="unknown"
      category="unknown"

      # Read manifest.json if exists
      if [[ -f "$dir/manifest.json" ]]; then
        version=$(node -e "console.log(JSON.parse(require('fs').readFileSync('$dir/manifest.json','utf8')).version||'unknown')" 2>/dev/null || echo "unknown")
        category=$(node -e "console.log(JSON.parse(require('fs').readFileSync('$dir/manifest.json','utf8')).category||'unknown')" 2>/dev/null || echo "unknown")
      fi

      # Check SKILL.md existence
      has_skill_md="false"
      [[ -f "$dir/SKILL.md" ]] && has_skill_md="true"

      # Check knowledge/ directory
      has_knowledge="false"
      [[ -d "$dir/knowledge" ]] && has_knowledge="true"

      # Check strategies/ directory
      has_strategies="false"
      [[ -d "$dir/strategies" ]] && has_strategies="true"

      echo "{\"name\":\"@botlearn/$name\",\"version\":\"$version\",\"category\":\"$category\",\"has_skill_md\":$has_skill_md,\"has_knowledge\":$has_knowledge,\"has_strategies\":$has_strategies}"
    done | paste -sd',' - | awk '{print "["$0"]"}')

    installed_count=$(echo "$skill_list" | node -e "console.log(JSON.parse(require('fs').readFileSync('/dev/stdin','utf8')).length)" 2>/dev/null || echo 0)
  fi

  # Try clawhub CLI for outdated/broken info
  if command -v clawhub &>/dev/null; then
    outdated=$(clawhub list --outdated --json 2>/dev/null || echo "[]")
    broken_deps=$(clawhub list --check-deps --json 2>/dev/null || echo "[]")
  fi

  # Check workspace skill discovery (OpenClaw v2026.3.1 workspace skills)
  workspace_skills_count=0
  if [[ -d "./skills" ]]; then
    workspace_skills_count=$(ls -d ./skills/*/ 2>/dev/null | wc -l | tr -d ' ')
  fi
fi

# Managed skills (global)
managed_skills_count=0
if [[ -d "$HOME/.openclaw/skills" ]]; then
  managed_skills_count=$(find "$HOME/.openclaw/skills" -name "SKILL.md" -maxdepth 3 2>/dev/null | wc -l | tr -d ' ')
fi

cat <<EOF
{
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "skills_dir": "$SKILLS_DIR",
  "skills_dir_exists": $skills_dir_exists,
  "installed_count": $installed_count,
  "skills": $skill_list,
  "outdated": $outdated,
  "broken_dependencies": $broken_deps,
  "workspace_skills_count": $workspace_skills_count,
  "managed_skills_count": $managed_skills_count,
  "clawhub_available": $(command -v clawhub &>/dev/null && echo true || echo false)
}
EOF
