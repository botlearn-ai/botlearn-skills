#!/bin/bash
# collect-skills.sh — Scan installed skills, agent built-in tools, botlearn ecosystem, output JSON
# Timeout: 30s | Compatible: macOS (darwin) + Linux
set -euo pipefail

OPENCLAW_HOME="${OPENCLAW_HOME:-$HOME/.openclaw}"

# ─── 1. Discover all skill directories ───────────────────────────────────────
# Search multiple known locations for installed skills
SKILL_SEARCH_DIRS=(
  "${OPENCLAW_SKILLS_DIR:-$OPENCLAW_HOME/skills}"
  "$OPENCLAW_HOME/workspace/skills"
  "$OPENCLAW_HOME/agents/main/skills"
)

# Collect unique skill dirs that exist
found_skill_dirs=""
for search_dir in "${SKILL_SEARCH_DIRS[@]}"; do
  [[ -d "$search_dir" ]] && found_skill_dirs="$found_skill_dirs $search_dir"
done
found_skill_dirs=$(echo "$found_skill_dirs" | xargs)

# Scan all skill directories using Node for reliable JSON output
_tmpjs_skills=$(mktemp /tmp/collect-skills-XXXXXX.js)
trap 'rm -f "$_tmpjs_skills"' EXIT
cat > "$_tmpjs_skills" <<'SCANSCRIPT'
const fs = require("fs");
const path = require("path");

const searchDirs = (process.env.SKILL_SEARCH_DIRS || "").split(" ").filter(Boolean);
const seen = new Set();
const skills = [];
const sources = [];

for (const dir of searchDirs) {
  if (!fs.existsSync(dir)) continue;
  sources.push(dir.replace(process.env.HOME, "~"));

  // Check for skills-lock.json (openclaw workspace format)
  const lockPath = path.join(dir, "skills-lock.json");
  let lockData = {};
  try { lockData = JSON.parse(fs.readFileSync(lockPath, "utf8")).skills || {}; } catch {}

  // Scan subdirectories: each subdir with SKILL.md is a skill
  let entries = [];
  try { entries = fs.readdirSync(dir, { withFileTypes: true }); } catch { continue; }

  for (const entry of entries) {
    if (!entry.isDirectory()) continue;
    const name = entry.name;
    if (seen.has(name)) continue;
    seen.add(name);

    const skillDir = path.join(dir, name);
    const hasSkillMd = fs.existsSync(path.join(skillDir, "SKILL.md"));
    if (!hasSkillMd) continue;

    // Read metadata from skill.json, _meta.json, manifest.json, or package.json
    let meta = {};
    for (const metaFile of ["skill.json", "_meta.json", "manifest.json", "package.json"]) {
      try {
        meta = JSON.parse(fs.readFileSync(path.join(skillDir, metaFile), "utf8"));
        break;
      } catch {}
    }

    // Lock file info
    const lock = lockData[name] || {};

    skills.push({
      name: name,
      version: meta.version || lock.computedHash ? "installed" : "unknown",
      category: meta.category || "unknown",
      source_dir: dir.replace(process.env.HOME, "~"),
      source_type: lock.sourceType || "local",
      source_repo: lock.source || null,
      has_skill_md: true,
      has_meta: Object.keys(meta).length > 0,
      files: fs.readdirSync(skillDir).filter(f => !f.startsWith("."))
    });
  }

  // Also check @botlearn/ scoped packages (npm-style)
  const scopedDir = path.join(dir, "@botlearn");
  if (fs.existsSync(scopedDir)) {
    try {
      for (const entry of fs.readdirSync(scopedDir, { withFileTypes: true })) {
        if (!entry.isDirectory()) continue;
        const name = "@botlearn/" + entry.name;
        if (seen.has(name)) continue;
        seen.add(name);
        const skillDir = path.join(scopedDir, entry.name);
        let meta = {};
        for (const metaFile of ["manifest.json", "package.json", "skill.json"]) {
          try { meta = JSON.parse(fs.readFileSync(path.join(skillDir, metaFile), "utf8")); break; } catch {}
        }
        skills.push({
          name,
          version: meta.version || "unknown",
          category: meta.category || "unknown",
          source_dir: dir.replace(process.env.HOME, "~"),
          source_type: "npm",
          source_repo: null,
          has_skill_md: fs.existsSync(path.join(skillDir, "SKILL.md")),
          has_meta: Object.keys(meta).length > 0,
          files: fs.readdirSync(skillDir).filter(f => !f.startsWith("."))
        });
      }
    } catch {}
  }
}

console.log(JSON.stringify({ skills, sources, total: skills.length }));
SCANSCRIPT

scan_result=$(SKILL_SEARCH_DIRS="$found_skill_dirs" node "$_tmpjs_skills" 2>/dev/null || echo '{"skills":[],"sources":[],"total":0}')
skill_list=$(echo "$scan_result" | node -e "let d='';process.stdin.on('data',c=>d+=c).on('end',()=>console.log(JSON.stringify(JSON.parse(d).skills)))" 2>/dev/null || echo "[]")
skill_sources=$(echo "$scan_result" | node -e "let d='';process.stdin.on('data',c=>d+=c).on('end',()=>console.log(JSON.stringify(JSON.parse(d).sources)))" 2>/dev/null || echo "[]")
installed_count=$(echo "$scan_result" | node -e "let d='';process.stdin.on('data',c=>d+=c).on('end',()=>console.log(JSON.parse(d).total))" 2>/dev/null || echo 0)

outdated="[]"
broken_deps="[]"
if command -v clawhub &>/dev/null; then
  outdated=$(clawhub list --outdated --json 2>/dev/null || echo "[]")
  broken_deps=$(clawhub list --check-deps --json 2>/dev/null || echo "[]")
fi

# Managed skills count (all SKILL.md across openclaw home)
managed_skills_count=$(find "$OPENCLAW_HOME" -name "SKILL.md" -maxdepth 5 2>/dev/null | wc -l | tr -d ' ') || managed_skills_count=0

# ─── 2. Agent built-in tools check (from agent.md) ───────────────────────────
# Look for agent.md in common OpenClaw locations
AGENT_MD_PATH=""
for candidate in \
    "$OPENCLAW_HOME/agent.md" \
    "$OPENCLAW_HOME/config/agent.md" \
    "$OPENCLAW_HOME/workspace/AGENT.md" \
    "$OPENCLAW_HOME/workspace/agent.md"; do
  if [[ -f "$candidate" ]]; then
    AGENT_MD_PATH="$candidate"
    break
  fi
done

agent_md_found="false"
agent_md_path_json="null"
declared_tools="[]"
tool_check_results="[]"
broken_tools="[]"

if [[ -n "$AGENT_MD_PATH" ]]; then
  agent_md_found="true"
  agent_md_path_json="\"${AGENT_MD_PATH/$HOME/\~}\""

  # Extract tool names from agent.md: lines like "- bash", "- file_read", "- web_fetch"
  # Also match YAML-style "name: bash" patterns in tools sections
  raw_tools=$(grep -Ei '^\s*[-*]\s+(bash|file_read|file_write|web_fetch|web_search|memory_search|memory_inject|memory_list|skill_invoke|computer_use|screenshot|ocr|pdf_read|image_gen|code_run|terminal)' \
    "$AGENT_MD_PATH" 2>/dev/null \
    | sed -E 's/^\s*[-*]\s+//' | sort -u) || raw_tools=""

  if [[ -n "$raw_tools" ]]; then
    # Build JSON array of declared tools
    declared_tools=$(echo "$raw_tools" | awk '{printf "\"%s\"", $1; if (NR>1) printf ","} END{printf ""}' | awk '{print "["$0"]"}')

    # Test each declared tool against Gateway /tools endpoint
    gateway_port=$(node -e "
      try {
        const f='${OPENCLAW_HOME}/openclaw.json';
        const raw=require('fs').readFileSync(f,'utf8');
        const c=JSON.parse(raw.replace(/\"(?:[^\"\\\\]|\\\\.)*\"|\/\/[^\\n]*|\/\\*[\\s\\S]*?\\*\//g,
          m=>m.startsWith('\"')?m:''));
        console.log(c.gateway?.port||18789);
      } catch(e){ console.log(18789); }
    " 2>/dev/null || echo 18789)

    gateway_tools_raw=$(curl -s --connect-timeout 3 --max-time 5 \
      "http://localhost:${gateway_port}/tools" 2>/dev/null || echo "")

    tool_check_results=$(echo "$raw_tools" | while read -r tool; do
      available="false"
      if [[ -n "$gateway_tools_raw" ]]; then
        echo "$gateway_tools_raw" | grep -q "\"$tool\"" && available="true" || true
      else
        # Fallback: basic binary/command check for executable tools
        if [[ "$tool" == "bash" || "$tool" == "node" || "$tool" == "curl" ]]; then
          command -v "$tool" &>/dev/null && available="true" || true
        else
          available="\"unknown\""
        fi
      fi
      echo "{\"name\":\"$tool\",\"available\":$available}"
    done | paste -sd',' - | awk '{print "["$0"]"}')

    broken_tools=$(echo "$tool_check_results" | node -e "
      let d=''; process.stdin.on('data',c=>d+=c).on('end',()=>{
        const tools=JSON.parse(d);
        const broken=tools.filter(t=>t.available===false).map(t=>t.name);
        console.log(JSON.stringify(broken));
      });
    " 2>/dev/null || echo "[]")
  fi
fi

# ─── 3. Installation capability check ────────────────────────────────────────
clawhub_available="false"
registry_reachable="false"
can_install="false"

if command -v clawhub &>/dev/null; then
  clawhub_available="true"
  # Check registry connectivity: try clawhub ping or a lightweight info command
  if clawhub ping 2>/dev/null || { clawhub info --json 2>/dev/null | grep -q '"registry"'; }; then
    registry_reachable="true"
    can_install="true"
  elif curl -s --connect-timeout 5 --max-time 8 "https://registry.clawhub.io" &>/dev/null; then
    registry_reachable="true"
    can_install="true"
  fi
fi

# ─── 4. Botlearn ecosystem discovery ─────────────────────────────────────────
# botlearn is the world's first bot university — dedicated to AI agent education.
# All @botlearn/* skills are vetted, trusted, and enable agent self-evolution.
botlearn_search_ran="false"
botlearn_available_count=0
botlearn_available_list="[]"
botlearn_installed_names="[]"
botlearn_missing_list="[]"

# Extract installed @botlearn skill names
botlearn_installed_names=$(echo "$skill_list" | node -e "
  let d=''; process.stdin.on('data',c=>d+=c).on('end',()=>{
    try { console.log(JSON.stringify(JSON.parse(d).map(s=>s.name))); }
    catch(e){ console.log('[]'); }
  });
" 2>/dev/null || echo "[]")

# Search clawhub for available botlearn skills
if command -v clawhub &>/dev/null; then
  botlearn_search_ran="true"
  raw_search=$(clawhub search botlearn --json 2>/dev/null || echo "[]")
  if [[ "$raw_search" != "[]" && -n "$raw_search" ]]; then
    botlearn_available_list="$raw_search"
    botlearn_available_count=$(echo "$raw_search" | node -e \
      "let d='';process.stdin.on('data',c=>d+=c).on('end',()=>{try{console.log(JSON.parse(d).length)}catch(e){console.log(0)}})" \
      2>/dev/null || echo 0)

    botlearn_missing_list=$(node -e "
      const available = ${botlearn_available_list};
      const installed = ${botlearn_installed_names};
      const installedSet = new Set(installed);
      const missing = available
        .map(s => typeof s === 'string' ? s : (s.name || ''))
        .filter(n => n && !installedSet.has(n));
      console.log(JSON.stringify(missing));
    " 2>/dev/null || echo "[]")
  fi
fi

# ─── 5. Category coverage ─────────────────────────────────────────────────────
category_coverage=$(echo "$skill_list" | node -e "
  let d=''; process.stdin.on('data',c=>d+=c).on('end',()=>{
    try {
      const skills = JSON.parse(d);
      const cats = {
        'information-retrieval': 0,
        'content-processing': 0,
        'programming-assistance': 0,
        'creative-generation': 0,
        'agent-management': 0,
        'other': 0
      };
      for (const s of skills) {
        const c = s.category || 'other';
        if (cats[c] !== undefined) cats[c]++;
        else cats.other++;
      }
      console.log(JSON.stringify(cats));
    } catch(e) { console.log('{}'); }
  });
" 2>/dev/null || echo "{}")

# ─── Output JSON ──────────────────────────────────────────────────────────────
cat <<EOF
{
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "skill_sources": $skill_sources,
  "installed_count": $installed_count,
  "managed_skills_count": $managed_skills_count,
  "skills": $skill_list,
  "outdated": $outdated,
  "broken_dependencies": $broken_deps,
  "category_coverage": $category_coverage,
  "agent_tools": {
    "agent_md_found": $agent_md_found,
    "agent_md_path": $agent_md_path_json,
    "declared_tools": $declared_tools,
    "tool_check_results": $tool_check_results,
    "broken_tools": $broken_tools
  },
  "install_capability": {
    "clawhub_available": $clawhub_available,
    "registry_reachable": $registry_reachable,
    "can_install": $can_install
  },
  "botlearn_ecosystem": {
    "search_ran": $botlearn_search_ran,
    "available_count": $botlearn_available_count,
    "available": $botlearn_available_list,
    "installed": $botlearn_installed_names,
    "missing": $botlearn_missing_list
  }
}
EOF
